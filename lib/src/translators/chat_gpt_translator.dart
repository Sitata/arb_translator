import 'dart:io';

import 'package:console/console.dart';
import 'package:dart_openai/dart_openai.dart';

class ChatGptTranslator {
  final List<String> translateList;
  String targetLanguageCode;
  String apiKey;
  String chatGptModel;
  String? organizationId;

  ChatGptTranslator({
    required this.translateList,
    required this.targetLanguageCode,
    required this.apiKey,
    required this.chatGptModel,
    this.organizationId,
  });

  /// translate string list and return translations
  Future<List<String>> translate() async {
    OpenAI.apiKey = apiKey;
    print('• Using model $chatGptModel');

    if (organizationId != null) {
      OpenAI.organization = organizationId;
      print('• Using Organization ID $organizationId');
    }

    final translated = <String>[];

    for (String str in translateList) {
      String result = await _doTranslationFor(str);
      translated.add(result);
    }

    return translated;
  }

  String _prompt(String str) {
    return 'You will be provided with a sentence, phrase, series of words or a single word that is written with a language whose language code is: en, and your task is to translate it into another language with language code: $targetLanguageCode. The format of the sentence is html. Do not translate anything between html elements that have an attribute of "notranslate". Do not translate any html attributes either. The sentence is the following: $str';
  }

  Future<String> _doTranslationFor(String str) async {
    print(str);

    try {
      OpenAIChatCompletionModel completion = await OpenAI.instance.chat.create(
        model: chatGptModel,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: _prompt(str),
            role: OpenAIChatMessageRole.user,
          ),
        ],
        temperature: 0,
      );
      if (completion.choices.isNotEmpty) {
        // pick first answer
        OpenAIChatCompletionChoiceModel choice = completion.choices.first;
        if (choice.finishReason == 'stop') {
          // good result
          return choice.message.content;
        } else {
          // anything but a good result and we should raise error and quit
          Console.setTextColor(1, bright: true);
          stderr.write('Error during chatgpt completion.');
          stderr.write('Finish reason was: ${choice.finishReason}');
          stderr.write('Input sentence was: $str');
          exit(2);
        }
      }
    } on RequestFailedException catch (e) {
      Console.setTextColor(1, bright: true);
      stderr.write('Error during chatgpt completion.');
      print(e.message);
      print(e.statusCode);
      exit(2);
    }
    return '';
  }
}
