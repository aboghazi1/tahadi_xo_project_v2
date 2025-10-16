import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(TahadiApp());
}

class TahadiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تحدي XO الحروف',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String teamA = 'الفريق الأول';
  String teamB = 'الفريق الثاني';
  List<String> allCategories = [
    'الكويت','السعودية','معلومات عامة','اسلامية','كرة قدم','رياضة متنوعة',
    'افلام','مسلسلات خليجية','انمي','كرة سلة امريكية','براندات','عطور',
    'منتجات','شعارات','علوم','كرتون قديم','سبيستون'
  ];
  List<String> selectedCategories = [];
  List<Map<String,dynamic>> questions = [];
  bool loading = true;

  @override
  void initState(){
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final s = await rootBundle.loadString('assets/questions.json');
    final data = json.decode(s) as List<dynamic>;
    questions = data.map((e)=>Map<String,dynamic>.from(e)).toList();
    setState(()=>loading=false);
  }

  void openSetup() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SetupPage(
      teamA: teamA, teamB: teamB, allCategories: allCategories, selected: selectedCategories,
      onSave: (a,b,sel){
        setState(()=>{teamA=a; teamB=b; selectedCategories=sel;});
      },
    )));
  }

  void openSubGame(int index){
    if(selectedCategories.length < 4){
      selectedCategories = allCategories.take(4).toList();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GamePage(
      subIndex: index+1,
      teamA: teamA,
      teamB: teamB,
      categories: selectedCategories,
      questions: questions,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تحدي XO الحروف'),
          actions: [
            IconButton(icon: Icon(Icons.settings), onPressed: openSetup),
          ],
        ),
        body: loading ? Center(child:CircularProgressIndicator()) : Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text('الفرق', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
              SizedBox(height:8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Chip(label: Text(teamA)),
                  Chip(label: Text(teamB)),
                ],
              ),
              SizedBox(height:16),
              Text('اختر لعبة فرعية (5 ألعاب):', style: TextStyle(fontSize:16)),
              SizedBox(height:12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2),
                  itemCount: 5,
                  itemBuilder: (ctx,i){
                    return GestureDetector(
                      onTap: ()=>openSubGame(i),
                      child: Card(
                        elevation:4,
                        child: Center(
                          child: Text('اللعبة الفرعية ${i+1}', style: TextStyle(fontSize:18)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height:8),
              Text('الفئات المختارة: ${selectedCategories.isEmpty? allCategories.take(4).join('، '): selectedCategories.join('، ')}', textAlign: TextAlign.center),
              SizedBox(height:8),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupPage extends StatefulWidget {
  final String teamA, teamB;
  final List<String> allCategories;
  final List<String> selected;
  final Function(String,String,List<String>) onSave;
  SetupPage({required this.teamA, required this.teamB, required this.allCategories, required this.selected, required this.onSave});
  @override
  _SetupPageState createState()=>_SetupPageState();
}

class _SetupPageState extends State<SetupPage>{
  late TextEditingController aCtrl;
  late TextEditingController bCtrl;
  late List<String> sel;
  @override
  void initState(){
    super.initState();
    aCtrl = TextEditingController(text: widget.teamA);
    bCtrl = TextEditingController(text: widget.teamB);
    sel = List.from(widget.selected);
    if(sel.isEmpty) sel = widget.allCategories.take(4).toList();
  }
  @override
  Widget build(BuildContext context){
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('إعدادات التحدي')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children:[
              TextField(controller: aCtrl, decoration: InputDecoration(labelText: 'اسم الفريق الأول')),
              TextField(controller: bCtrl, decoration: InputDecoration(labelText: 'اسم الفريق الثاني')),
              SizedBox(height:12),
              Text('اختر 4 فئات:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView(
                  children: widget.allCategories.map((c){
                    bool checked = sel.contains(c);
                    return CheckboxListTile(
                      title: Text(c),
                      value: checked,
                      onChanged: (v){
                        setState((){
                          if(v==true){
                            if(sel.length<4) sel.add(c);
                          } else {
                            sel.remove(c);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: (){
                  if(sel.length!=4){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرجاء اختيار 4 فئات')));
                    return;
                  }
                  widget.onSave(aCtrl.text.trim(), bCtrl.text.trim(), sel);
                  Navigator.of(context).pop();
                },
                child: Text('حفظ والبدء'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget{
  final int subIndex;
  final String teamA, teamB;
  final List<String> categories;
  final List<Map<String,dynamic>> questions;
  GamePage({required this.subIndex, required this.teamA, required this.teamB, required this.categories, required this.questions});
  @override
  _GamePageState createState()=>_GamePageState();
}

class _GamePageState extends State<GamePage>{
  List<String> arabicLetters = ['ا','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي'];
  List<String> board = List.filled(9,'');
  String turn = 'A'; // A or B
  int scoreA = 0, scoreB = 0;
  Random rnd = Random();
  bool blockNext = false;
  bool usedSteal = false;
  bool usedHard = false;

  void onCellTap(int idx) async {
    if(board[idx].isNotEmpty) return;
    if(blockNext){
      setState(()=>blockNext=false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم منع الدور هذه المرة')));
      setState(()=>turn = (turn=='A')?'B':'A');
      return;
    }
    String letter = arabicLetters[rnd.nextInt(arabicLetters.length)];
    var pool = widget.questions.where((q)=> q['letter']==letter && widget.categories.contains(q['category'])).toList();
    if(pool.isEmpty){
      pool = widget.questions.where((q)=> q['letter']==letter).toList();
    }
    if(pool.isEmpty){
      markCell(idx, letter);
      return;
    }
    Map<String,dynamic> q = pool[rnd.nextInt(pool.length)];
    bool correct = await showQuestionDialog(q['question'], q['answer'], letter);
    if(correct){
      markCell(idx, letter);
    } else {
      setState(()=>turn = (turn=='A')?'B':'A');
    }
  }

  Future<bool> showQuestionDialog(String question, String answer, String requiredLetter) async {
    TextEditingController ctrl = TextEditingController();
    bool result = false;
    await showDialog(context: context, builder: (ctx){
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('السؤال (الإجابة يجب أن تبدأ بحرف "$requiredLetter")'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              Text(question),
              SizedBox(height:8),
              TextField(controller: ctrl, decoration: InputDecoration(labelText: 'أدخل إجابتك (يجب أن تبدأ بالحرف)')),
            ],
          ),
          actions:[
            TextButton(onPressed: ()=>Navigator.of(ctx).pop(), child: Text('إلغاء')),
            ElevatedButton(onPressed: (){
              String given = ctrl.text.trim();
              if(given.isEmpty) { Navigator.of(ctx).pop(); return; }
              String firstChar = given[0];
              if(firstChar == requiredLetter){
                result = true;
              } else {
                result = false;
              }
              Navigator.of(ctx).pop();
            }, child: Text('تحقق')),
          ],
        ),
      );
    });
    return result;
  }

  void markCell(int idx, String letter){
    setState((){
      board[idx] = (turn=='A') ? 'X' : 'O';
      if(checkWin(board[idx])){
        String owner = board[idx];
        if(owner=='X') scoreA++; else scoreB++;
        showRoundResult(owner);
      } else {
        turn = (turn=='A')?'B':'A';
      }
    });
  }

  bool checkWin(String owner){
    List<List<int>> wins = [
      [0,1,2],[3,4,5],[6,7,8],
      [0,3,6],[1,4,7],[2,5,8],
      [0,4,8],[2,4,6],
    ];
    for(var w in wins){
      if(board[w[0]]==owner && board[w[1]]==owner && board[w[2]]==owner) return true;
    }
    return false;
  }

  void showRoundResult(String owner){
    String winnerName = owner=='X' ? widget.teamA : widget.teamB;
    String loserName = owner=='X' ? widget.teamB : widget.teamA;
    String message = '';
    if((owner=='X' && scoreA==3 && scoreB==0) || (owner=='O' && scoreB==3 && scoreA==0)){
      message = 'كفو $winnerName فوز ساحق هاترك 👌🏻';
    } else if((owner=='X' && scoreA==3 && scoreB==1) || (owner=='O' && scoreB==3 && scoreA==1)){
      message = 'الف مبروك الفريق الفايز هو $winnerName فوز سهل';
    } else if((owner=='X' && scoreA==3 && scoreB==2) || (owner=='O' && scoreB==3 && scoreA==2)){
      message = 'منافسة قوية هاردلك ${loserName} الفايز هو $winnerName';
    } else {
      message = 'فاز $winnerName بالجولة';
    }

    showDialog(context: context, builder: (ctx){
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('نتيجة الجولة'),
          content: Column(mainAxisSize: MainAxisSize.min, children:[
            Text(message),
            SizedBox(height:8),
            Text('النتيجة الحالية: ${widget.teamA} $scoreA - ${widget.teamB} $scoreB'),
          ]),
          actions: [
            TextButton(onPressed: (){
              Navigator.of(ctx).pop();
              if(scoreA>=3 || scoreB>=3){
                showFinalWinner();
              } else {
                setState((){
                  board = List.filled(9,'');
                  turn = 'A';
                });
              }
            }, child: Text('متابعة')),
          ],
        ),
      );
    });
  }

  void showFinalWinner(){
    String winner = scoreA>scoreB ? widget.teamA : widget.teamB;
    showDialog(context: context, builder: (ctx){
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('المبروك!'),
          content: Column(mainAxisSize: MainAxisSize.min, children:[
            Text('الفريق الفايز هو $winner 🏆'),
            SizedBox(height:8),
            Text('اضغط إعادة للعب مرة أخرى'),
          ]),
          actions: [
            TextButton(onPressed: (){
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            }, child: Text('الخروج')),
            ElevatedButton(onPressed: (){
              setState((){
                board = List.filled(9,'');
                turn = 'A';
                scoreA = 0; scoreB = 0;
              });
              Navigator.of(ctx).pop();
            }, child: Text('إعادة')),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context){
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('اللعبة الفرعية ${widget.subIndex}')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children:[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                Column(crossAxisAlignment: CrossAxisAlignment.end, children:[
                  Text(widget.teamA, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('نقاط: $scoreA'),
                ]),
                Column(children:[Text('جولة XO الحروف'), Text('فئات: ${widget.categories.join('، ')}', style: TextStyle(fontSize:12))]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text(widget.teamB, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('نقاط: $scoreB'),
                ]),
              ]),
              SizedBox(height:12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: 9,
                  itemBuilder: (ctx,i){
                    return GestureDetector(
                      onTap: ()=>onCellTap(i),
                      child: Card(
                        child: Center(child: Text(board[i], style: TextStyle(fontSize:36))),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height:8),
              Text('دور: ${turn=='A' ? widget.teamA : widget.teamB}'),
              SizedBox(height:8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children:[
                ElevatedButton(onPressed: (){
                  if(!blockNext){
                    setState(()=>blockNext=true);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تفعيل سكب: يمنع الدور التالي')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الوسيلة مستخدمة')));
                  }
                }, child: Text('سكب')),
                ElevatedButton(onPressed: (){
                  if(!usedSteal){
                    setState(()=>usedSteal=true);
                    showStealDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الواسطة مستخدمة')));
                  }
                }, child: Text('واسطة')),
                ElevatedButton(onPressed: (){
                  if(!usedHard){
                    setState(()=>usedHard=true);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('زيادة الصعوبة مفعلة: الاسئلة ستكون أصعب')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مستخدمة')));
                  }
                }, child: Text('زيادة الصعوبة')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void showStealDialog(){
    TextEditingController ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx){
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('الواسطة: اختر خانة مسروقة'),
          content: Column(mainAxisSize: MainAxisSize.min, children:[
            Text('ادخل رقم الخانة (1-9) التي تريد سرقتها (يجب أن تكون مشغولة للسرقة)'),
            TextField(controller: ctrl, keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(onPressed: ()=>Navigator.of(ctx).pop(), child: Text('إلغاء')),
            ElevatedButton(onPressed: (){
              int idx = int.tryParse(ctrl.text.trim()) ?? -1;
              if(idx<1 || idx>9 || board[idx-1].isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خانة غير صالحة')));
                return;
              }
              String letter = arabicLetters[rnd.nextInt(arabicLetters.length)];
              var pool = widget.questions.where((q)=> q['letter']==letter && widget.categories.contains(q['category'])).toList();
              if(pool.isEmpty) pool = widget.questions.where((q)=> q['letter']==letter).toList();
              if(pool.isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا توجد اسئلة متاحة للسرقة')));
                Navigator.of(ctx).pop();
                return;
              }
              Map<String,dynamic> q = pool[rnd.nextInt(pool.length)];
              Navigator.of(ctx).pop();
              showQuestionDialog(q['question'], q['answer'], letter).then((correct){
                if(correct){
                  setState(()=> board[idx-1] = (turn=='A')?'X':'O');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('نجحت الواسطة!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشلت الواسطة')));
                }
              });
            }, child: Text('اختبار')),
          ],
        ),
      );
    });
  }
}