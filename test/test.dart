import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:unittest/src/utils.dart';

import 'util_test.dart' as util;

void main() {
  unittestConfiguration = new LoggingHtmlEnhancedConfiguration();

  util.runTests();
}

class LoggingHtmlEnhancedConfiguration extends HtmlEnhancedConfiguration {
  LoggingHtmlEnhancedConfiguration() : super(false);

  void onTestResult(TestCase testCase) {
    super.onTestResult(testCase);

    if (testCase.stackTrace != null) {
      StringBuffer buffer = new StringBuffer(testCase.message);

      getTrace(testCase.stackTrace, true, true)
        .frames
        .forEach((frame) {
          buffer.write('${frame.member} (${frame.uri}');

          if (frame.line != null) {
            buffer.write(':${frame.line}');
          }

          buffer.write(')\n');
        });

      window.console.error(buffer.toString());
    }
  }
}
