import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

/// Start Online Lawyer Chat API Group Code

class OnlineLawyerChatAPIGroup {
  static String getBaseUrl({
    String? apiKey = '',
    String? askGPT = 'hola',
    String? statusResponse = 'f',
  }) =>
      'https://api.openai.com/v1';
  static Map<String, String> headers = {};
  static GetAChatCompletionFromGPT4Call getAChatCompletionFromGPT4Call =
      GetAChatCompletionFromGPT4Call();
}

class GetAChatCompletionFromGPT4Call {
  Future<ApiCallResponse> call({
    String? apiKey = '',
    String? askGPT = 'hola',
    String? statusResponse = 'f',
  }) async {
    final baseUrl = OnlineLawyerChatAPIGroup.getBaseUrl(
      apiKey: apiKey,
      askGPT: askGPT,
      statusResponse: statusResponse,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "${statusResponse}You are a helpful assistant that understands immigration LAWS from the United States and know about USCIS and their forms and processing times, you will read this json of the status tracker api response and answer questions from the user. Response from USCIS about case entered by the user "
    },
    {
      "role": "user",
      "content": "${askGPT}"
    }
  ]
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get a chat completion from GPT-4',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End Online Lawyer Chat API Group Code

class GetstatusCall {
  static Future<ApiCallResponse> call({
    String? caseid = 'd',
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getstatus',
      apiUrl: 'https://api-int.uscis.gov/case-status/${caseid}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UscisTokenCall {
  static const _clientId = String.fromEnvironment('USCIS_CLIENT_ID');
  static const _clientSecret = String.fromEnvironment('USCIS_CLIENT_SECRET');

  static Future<ApiCallResponse> call() async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      return const ApiCallResponse(
        {
          'error':
              'USCIS API credentials are not configured. Use a private backend proxy for production refresh.',
        },
        {},
        400,
      );
    }

    return ApiManager.instance.makeApiCall(
      callName: 'UscisToken',
      apiUrl: 'https://api-int.uscis.gov/oauth/accesstoken',
      callType: ApiCallType.POST,
      headers: {
        'content-type': 'application/x-www-form-urlencoded',
      },
      params: {
        'grant_type': "client_credentials",
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
      bodyType: BodyType.X_WWW_FORM_URL_ENCODED,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? accessToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.access_token''',
      ));
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}
