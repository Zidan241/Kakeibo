import 'package:flutter/material.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  String _response = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null) {
      stderr.writeln(r'No $GEMINI_API_KEY environment variable');
      return;
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system('You are an experienced financial advisor who is capable of providing thoughtful and meaningful financial and budgetting advice. Help the user with their monthly budget'),
    );

    final chat = model.startChat(history: [
      Content.multi([
        TextPart('Here is my personal information:\nI am 25 years old\nI am single\nI live in Cairo egypt\nI am male\n\nSuggest a monthly financial budget for me in my local currency, taking into consideration local pricing'),
      ]),
      Content.model([
        TextPart('```json\n{\n"income": {\n"salary": 0,\n"otherIncome": 0,\n"totalIncome": 0\n},\n"expenses": {\n"essential": {\n"housing": 3000,\n"transportation": 1000,\n"groceries": 2000,\n"utilities": 500,\n"healthcare": 500,\n"personalCare": 500,\n"totalEssential": 7500\n},\n"nonEssential": {\n"entertainment": 1000,\n"diningOut": 500,\n"shopping": 500,\n"travel": 500,\n"hobbies": 500,\n"totalNonEssential": 3000\n},\n"financial": {\n"emergencyFund": 500,\n"investments": 500,\n"totalFinancial": 1000\n},\n"totalExpenses": 11500\n},\n"savings": {\n"targetSavings": 1000,\n"actualSavings": 0\n},\n"notes": [\n"This budget is a suggestion and may need to be adjusted based on your individual circumstances.",\n"Housing costs can vary greatly depending on location and type of accommodation. Adjust accordingly.",\n"Consider using public transportation or ride-sharing services to save on transportation costs.",\n"Cooking at home more often can help reduce dining out expenses.",\n"Set aside an emergency fund to cover unexpected expenses.",\n"Explore investment options to grow your wealth over time."\n],\n"currency": "EGP"\n}\n\n\n```'),
      ]),
    ]);

    final message = 'INSERT_INPUT_HERE';
    final content = Content.text(message);

    final response = await chat.sendMessage(content);
    setState(() {
      _response = response.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gemini Report",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_response),
        ),
      ),
    );
  }
}
