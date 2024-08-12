import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:typeset/typeset.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({Key? key}) : super(key: key);

  @override
  _AIScreenState createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  String _response = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;
    if (apiKey == null) {
      stderr.writeln(r'No $GEMINI_API_KEY environment variable');
      return;
    }

    // final model = GenerativeModel(
    //   model: 'gemini-1.5-pro',
    //   apiKey: apiKey,
    //   generationConfig: GenerationConfig(
    //     temperature: 1,
    //     topK: 64,
    //     topP: 0.95,
    //     maxOutputTokens: 8192,
    //     responseMimeType: 'application/json',
    //   ),
    //   systemInstruction: Content.system(
    //       'You are an experienced financial advisor who is capable of providing thoughtful and meaningful financial and budgetting advice. Help the user with their monthly budget'),
    // );

    // final chat = model.startChat(history: [
    //   Content.multi([
    //     TextPart(
    //         'Here is my personal information:\nI am 25 years old\nI am single\nI live in Cairo egypt\nI am male\n\nSuggest a monthly financial budget for me in my local currency, taking into consideration local pricing'),
    //   ]),
    //   Content.model([
    //     TextPart(
    //         '```json\n{\n"income": {\n"salary": 0,\n"otherIncome": 0,\n"totalIncome": 0\n},\n"expenses": {\n"essential": {\n"housing": 3000,\n"transportation": 1000,\n"groceries": 2000,\n"utilities": 500,\n"healthcare": 500,\n"personalCare": 500,\n"totalEssential": 7500\n},\n"nonEssential": {\n"entertainment": 1000,\n"diningOut": 500,\n"shopping": 500,\n"travel": 500,\n"hobbies": 500,\n"totalNonEssential": 3000\n},\n"financial": {\n"emergencyFund": 500,\n"investments": 500,\n"totalFinancial": 1000\n},\n"totalExpenses": 11500\n},\n"savings": {\n"targetSavings": 1000,\n"actualSavings": 0\n},\n"notes": [\n"This budget is a suggestion and may need to be adjusted based on your individual circumstances.",\n"Housing costs can vary greatly depending on location and type of accommodation. Adjust accordingly.",\n"Consider using public transportation or ride-sharing services to save on transportation costs.",\n"Cooking at home more often can help reduce dining out expenses.",\n"Set aside an emergency fund to cover unexpected expenses.",\n"Explore investment options to grow your wealth over time."\n],\n"currency": "EGP"\n}\n\n\n```'),
    //   ]),
    // ]);

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      // safetySettings: Adjust safety settings
      // See https://ai.google.dev/gemini-api/docs/safety-settings
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
      systemInstruction: Content.system(
          '# Monthly Financial Report Prompt\n\nPlease provide a brief financial report for a users spending in the past month, following this structure:\n\n1. **Total Spending**: State the total amount spent this month.\n\n2. **Top 3 Expense Categories**: List the three categories where you spent the most money, along with the amount for each.\n\n3. **Comparison to Previous Month**: Briefly compare your total spending to last month. Was it higher, lower, or about the same? By what percentage did it change?\n\n4. **Unusual Expenses**: Mention any significant one-time expenses that occurred this month.\n\n5. **Savings**: State how much you were able to save this month, if applicable.\n\n6. **Budget Adherence**: Briefly comment on whether you stayed within your budget for the month. If not, which categories exceeded the budget?\n\n7. **Goal for Next Month**: Set one financial goal for the upcoming month based on this report.\n\nPlease keep each section concise, ideally 1-2 sentences each. The entire report should be no more than 200 words.\n\nAs a rule of thumb, the budget can be divided into:\n- 50% for the users needs\n- 30% for the users wants\n- 20% for the users savings\nThe recommendation can vary greatly from this rule of thumb if it is suitable for the user\n\nThe user will personal details on their age, location, monthly budget and risk tolerance. Use the information to create personalized financial recommendations for the user\n\n Extensivley use markdown and make the report as readable and pretty as possible'),
    );

    final chat = model.startChat();

    final Housing = 2000;
    final Transportation = 500;
    final Food = 1000;
    final Utilities = 300;
    final Insurance = 200;
    final Medical_Healthcare = 400;
    final Saving_Investing_Debt_Payments = 500;
    final Personal_Spending = 300;
    final Recreation_Entertainment = 200;
    final Miscellaneous = 100;

    final message = '''
Here's my financial data for July 2024:

    Total spending: \$3,250

    Expense breakdown:

        Housing: \$1,200

        Food: \$600

        Transportation: \$400

        Entertainment: \$300

        Utilities: \$250

        Shopping: \$300

        Miscellaneous: \$200

    June 2024 total spending: \$3,100

    Unusual expenses:

        New laptop purchase: \$1,000

    Amount saved: \$500

    Monthly budget: \$3,000

    Financial goals:

        Reduce food expenses

        Increase savings rate
  ''';
    final content = Content.text(message);

    final response = await chat.sendMessage(content);
    setState(() {
      if (response.text != null) {
        _response = response.text!;
      } else {
        _response = "";
      }
    });
  }

  String _formatFinancialReport(String text) {
    final regex = RegExp(r'\$?\d+[\d,]*(\.\d+)?%?');
    return text.replaceAllMapped(regex, (match) {
      return '<b><color>${match.group(0)}</color></b>';
    });
  }

  Widget _buildFormattedReport(String formattedText) {
    final spans = _parseFormattedText(formattedText);
    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final regex = RegExp(r'(<b><color>.*?</color></b>)');
    final matches = regex.allMatches(text);
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      final matchedText = match.group(0);
      final cleanText = matchedText?.replaceAll(RegExp(r'<.*?>'), '');
      spans.add(TextSpan(
        text: cleanText,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          SvgPicture.asset(
            'assets/icons/google-gemini-icon.svg',
            width: 30,
            height: 30,
          ),
          SizedBox(width: 10), // Add this line for horizontal spacing
          const Text("Gemini Financial Report")
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   children: [
            //     SvgPicture.asset(
            //       'assets/icons/google-gemini-icon.svg',
            //       width: 30,
            //       height: 30,
            //     ),
            //     SizedBox(width: 10),
            //     Text(
            //       'Your financial report:',
            //     ),
            //   ],
            // ),
            SizedBox(height: 10),
            // Text(
            //   _response,
            // ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(child: TypeSet(_response)),
            ),
            // Add other widgets from ReportScreen here
          ],
        ),
      ),
    );
  }
}
