
/// The WooCommerce SDK for Flutter. Bringing your ecommerce app to life easily with Flutter and Woo Commerce.

library woocommerce;
import 'dart:async';
import "dart:collection";
import 'dart:convert';
import 'dart:io';
import "dart:math";
import "dart:core";
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwttokenmcommerce/WooJWTResponse.dart';
import 'package:jwttokenmcommerce/local_db.dart';
import 'package:jwttokenmcommerce/signup.dart';
import 'package:jwttokenmcommerce/woocommerce_customer.dart';
/// Create a new Instance of [WooCommerce] and pass in the necessary parameters into the constructor.
///
/// For example
/// ``` WooCommerce myApi = WooCommerce(
///   baseUrl: yourbaseUrl, // For example  http://mywebsite.com or https://mywebsite.com or http://cs.mywebsite.com
///   consumerKey: consumerKey,
///  consumerSecret: consumerSecret);
///  ```


class WooCommerce{
static bool valid;
  /// Parameter, [baseUrl] is the base url of your site. For example, http://me.com or https://me.com.
  String baseUrl;

  /// Parameter [consumerKey] is the consumer key provided by WooCommerce, e.g. `ck_12abc34n56j`.
  String consumerKey;

  /// Parameter [consumerSecret] is the consumer secret provided by WooCommerce, e.g. `cs_1uab8h3s3op`.
  String consumerSecret;

  /// Returns if the website is https or not based on the [baseUrl] parameter.
  bool isHttp;

  /// Parameter(Optional) [apiPath], tells the SDK if there is a different path to your api installation.
  /// Useful if the websites woocommerce api path have been modified.
  String apiPath;

  /// Parameter(Optional) [isDebug], tells the library if it should _printToLog debug logs.
  /// Useful if you are debuging or in development.
  bool isDebug;

  WooCommerce({
    @required String baseUrl='http://10.0.0.210:8080/WebsiteWordpressChecking/wordpress-5.2.2/wordpress.com',
    @required String consumerKey='ck_46bee59719510f0af6b327cae5d9450c3d9a8431',
    @required String consumerSecret='cs_d03fb7dd03e3611800e4f5ba20ae5e7a8ce42da6',
    String apiPath = "/wp-json/wc/v3/",
    bool isDebug = false,
  }) {
    this.baseUrl = baseUrl;
    this.consumerKey = consumerKey;
    this.consumerSecret = consumerSecret;
    this.apiPath = apiPath;
    this.isDebug = isDebug;

    if (this.baseUrl.startsWith("https")) {
      this.isHttp = true;
    } else {
      this.isHttp = false;
    }
  }

  void _printToLog(String message) {
    if (isDebug) {
      print("WOOCOMMERCE LOG : " + message);
    }
  }

  String _authToken;
  String get authToken => _authToken;

  Uri queryUri;
  String get apiResourceUrl=> queryUri.toString();

  // Header to be sent for JWT authourization
  Map<String, String> _urlHeader = {
    'Authorization': ''
  };
  String get urlHeader => _urlHeader['Authorization'] = 'Bearer '+authToken;
  LocalDatabaseService _localDbService = LocalDatabaseService();
  /// Authenticates the user using WordPress JWT authentication and returns the access [_token] string.
  /// Associated endpoint : yourwebsite.com/wp-json/jwt-auth/v1/token
  Future authenticateViaJWT(
      {String username, String password}) async {
    final body = {
      'username': username,
      'password': password,
    };

    final response = await http.post(
      this.baseUrl + '/wp-json/jwt-auth/v1/token',
      body: body,
    );
     print(response.statusCode);
    if (response.statusCode >= 200 && response.statusCode < 300) {

      WooJWTResponse authResponse =
      WooJWTResponse.fromJson(json.decode(response.body));
      _authToken = authResponse.token;
      _localDbService.updateSecurityToken(_authToken);
      _urlHeader['Authorization'] = 'Bearer ${authResponse.token}';
      print('auth '+authToken);
      if(_authToken!=null){
        valid=true;
        print('not null');
      }
      else{
        print('null');
      }
      return _authToken;
    } else {
      throw new WooCommerceError.fromJson(json.decode(response.body));
    }
  }
  /// Authenticates the user via JWT and returns a WooCommerce customer object of the current logged in customer.
  loginCustomer({
    @required String username,
    @required String password,
  }) async{
    WooCustomer customer;
    try {
      var response = await authenticateViaJWT(username: username, password: password);
      _printToLog('attempted token : '+ response.toString());
      if (response is String){
        int id = await fetchLoggedInUserId();
        customer = await getCustomerById(id: id);
      }
      return customer;
    } catch (e) {
      return e.message;
    }

  }

  /// Confirm if a customer is logged in [true] or out [false].
  Future<bool> isCustomerLoggedIn() async{
    String sToken = await _localDbService.getSecurityToken();
    if (sToken == '0'){
      return false;
    }
    else {
      return true;
    }
  }

  /// Fetches already authenticated user, using Jwt
  ///
  /// Associated endpoint : /wp-json/wp/v2/users/me
  Future<int> fetchLoggedInUserId() async {
    _urlHeader['Authorization'] = 'Bearer '+_authToken;
    final response =
    await http.get(this.baseUrl +'/wp-json/jwt-auth/v1/users/me', headers: _urlHeader);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonStr = json.decode(response.body);
      if (jsonStr.length == 0)
        throw new WooCommerceError(
            code: 'wp_empty_user', message: "No user found or you dont have permission");
      _printToLog('account user fetch : '+jsonStr.toString());
      return jsonStr['id'];
    } else {
      WooCommerceError err =
      WooCommerceError.fromJson(json.decode(response.body));
      throw err;
    }
  }

  /// Log User out
  ///
  logUserOut() async {
    await _localDbService.deleteSecurityToken();
  }

  /// Creates a new Woocommerce Customer and returns the customer object.
  ///
  /// Accepts a customer object as required parameter.
  Future<bool> createCustomer (WooCustomer customer) async{
   // _printToLog('Creating Customer With info : ' + customer.toString());
    print('Creating Customer With info : ' + customer.toString());
    _setApiResourceUrl(path: 'customers');
    final response = await post(queryUri.toString(), customer.toJson());
    _printToLog('created customer : '+response.toString());
    print(response.toString());
    final cus = WooCustomer.fromJson(response);
    if (cus is WooCustomer){
      print('cus'+cus.toString()); //print to check the data
      return true;
    }else {

      return false;
    }
    //return WooCustomer.fromJson(response);
  }

  /// Returns a list of all [WooCustomer], with filter options.
  ///
  /// Related endpoint: https://woocommerce.github.io/woocommerce-rest-api-docs/#customers
 Future<List<WooCustomer>> getCustomers(
      {int page,
        int perPage,
        String search,
        List<int> exclude,
        List<int> include,
        int offset,
        String order,
        String orderBy,
        //String email,
        String role}) async {
    Map<String, dynamic> payload = {};

    ({'page': page, 'per_page': perPage, 'search': search,
      'exclude': exclude, 'include': include, 'offset': offset,
      'order': order, 'orderby': orderBy, //'email': email,
      'role': role,
    }
    ).forEach((k, v) {
      if(v != null) payload[k] = v.toString();
    });

    List<WooCustomer> customers = [];
    _setApiResourceUrl(path: 'customers', queryParameters: payload);

    final response = await get(queryUri.toString());
    _printToLog('response gotten : '+response.toString());
    for(var c in response){
      var customer = WooCustomer.fromJson(c);
      _printToLog('customers here : '+customer.toString());
      customers.add(customer);
    }
    return customers;
  }

  /// Returns a [WooCustomer], whoose [id] is specified.
  Future<WooCustomer>getCustomerById({@required int id}) async{
    WooCustomer customer;
    _setApiResourceUrl(path: 'customers/'+id.toString(),);
    final response = await get(queryUri.toString());
    customer = WooCustomer.fromJson(response);
    return customer;
  }


  /// Updates an existing Customer and returns the [WooCustomer] object.
  ///
  /// Related endpoint: https://woocommerce.github.io/woocommerce-rest-api-docs/#customer-properties.

  Future<WooCustomer> oldUpdateCustomer ({@required WooCustomer wooCustomer}) async{
    _printToLog('Updating customer With customerId : ' + wooCustomer.id.toString());
    _setApiResourceUrl(path: 'customers/'+wooCustomer.id.toString(),);
    final response = await put(queryUri.toString(), wooCustomer.toJson());
    return WooCustomer.fromJson(response);
  }

  Future<WooCustomer> updateCustomer ({@required int id, Map data}) async{
    _printToLog('Updating customer With customerId : ' + id.toString());
    _setApiResourceUrl(path: 'customers/'+id.toString(),);
    final response = await put(queryUri.toString(), data);
    return WooCustomer.fromJson(response);
  }

  /// Deletes an existing Customer and returns the [WooCustomer] object.
  ///
  /// Related endpoint: https://woocommerce.github.io/woocommerce-rest-api-docs/#customer-properties.

  Future<WooCustomer> deleteCustomer ({@required int customerId, reassign}) async{
    Map data = {
      'force': true,
    };
    if(reassign !=null) data['reassign'] = reassign;
    _printToLog('Deleting customer With customerId : ' + customerId.toString());
    _setApiResourceUrl(path: 'customers/'+customerId.toString(),);
    final response = await delete(queryUri.toString(), data);
    return WooCustomer.fromJson(response);
  }
  /// This Generates a valid OAuth 1.0 URL
  ///
  /// if [isHttps] is true we just return the URL with
  /// [consumerKey] and [consumerSecret] as query parameters
  String _getOAuthURL(String requestMethod, String endpoint) {
    String consumerKey = this.consumerKey;
    String consumerSecret = this.consumerSecret;

    String token = "";
    _printToLog('oauth token = : '+token);
    String url = this.baseUrl + apiPath + endpoint;
    bool containsQueryParams = url.contains("?");

    if (this.isHttp== true) {
      return url +
          (containsQueryParams == true
              ? "&consumer_key=" +
              this.consumerKey +
              "&consumer_secret=" +
              this.consumerSecret
              : "?consumer_key=" +
              this.consumerKey +
              "&consumer_secret=" +
              this.consumerSecret);
    }

    Random rand = Random();
    List<int> codeUnits = List.generate(10, (index) {
      return rand.nextInt(26) + 97;
    });

    /// Random string uniquely generated to identify each signed request
    String nonce = String.fromCharCodes(codeUnits);

    /// The timestamp allows the Service Provider to only keep nonce values for a limited time
    // epoch is a date and time from which a computer measures system time.
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
print('timne '+timestamp.toString());
    String parameters = "oauth_consumer_key=" +
        consumerKey +
        "&oauth_nonce=" +
        nonce +
        "&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
        timestamp.toString() +
        "&oauth_token=" +
        token +
        "&oauth_version=1.0&";

    if (containsQueryParams == true) {
      parameters = parameters + url.split("?")[1];
    } else {
      parameters = parameters.substring(0, parameters.length - 1);
    }

    Map<dynamic, dynamic> params = QueryString.parse(parameters);
    Map<dynamic, dynamic> treeMap = new SplayTreeMap<dynamic, dynamic>();
    treeMap.addAll(params);

    String parameterString = "";

    for (var key in treeMap.keys) {
      parameterString = parameterString +
          Uri.encodeQueryComponent(key) +
          "=" +
          treeMap[key] +
          "&";
    }

    parameterString = parameterString.substring(0, parameterString.length - 1);

    String method = requestMethod;
    String baseString = method +
        "&" +
        Uri.encodeQueryComponent(
            containsQueryParams == true ? url.split("?")[0] : url) +
        "&" +
        Uri.encodeQueryComponent(parameterString);

    String signingKey = consumerSecret + "&" + token;
    crypto.Hmac hmacSha1 =
    crypto.Hmac(crypto.sha1, utf8.encode(signingKey)); // HMAC-SHA1

    /// The Signature is used by the server to verify the
    /// authenticity of the request and prevent unauthorized access.
    /// Here we use HMAC-SHA1 method.
    crypto.Digest signature = hmacSha1.convert(utf8.encode(baseString));

    String finalSignature = base64Encode(signature.bytes);

    String requestUrl = "";

    if (containsQueryParams == true) {
      requestUrl = url.split("?")[0] +
          "?" +
          parameterString +
          "&oauth_signature=" +
          Uri.encodeQueryComponent(finalSignature);
    } else {
      requestUrl = url +
          "?" +
          parameterString +
          "&oauth_signature=" +
          Uri.encodeQueryComponent(finalSignature);
    }

    return requestUrl;
  }

  _handleError(dynamic response){
    if(response['message']==null){
      return response;
    }
    else {
      throw Exception(
          WooCommerceError.fromJson(response).toString());
    }
  }

  Exception _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
      case 401:
      case 404:
      case 500:
        throw Exception(
            WooCommerceError.fromJson(json.decode(response.body)).toString());
      default:
        throw Exception(
            "An error occurred, status code: ${response.statusCode}");
    }
  }

  // Get the auth token from db.

  getAuthTokenFromDb() async{
    _authToken = await _localDbService.getSecurityToken();
    return _authToken;
  }

  // Sets the Uri for an endpoint.
  String _setApiResourceUrl({
    @required String path,
    String host, port, queryParameters,
    bool isShop = false,
  }) {
    this.apiPath = "/wp-json/wc/v3/";
    if(isShop){
      this.apiPath = '/wp-json/wc/v3/product/';
    }
    else{
      this.apiPath = "/wp-json/wc/v3/";
    }
    //List<Map>param = [];
    // queryParameters.forEach((k, v) => param.add({k : v})); print(param.toString());
    getAuthTokenFromDb();
    queryUri = new Uri(path: path, queryParameters: queryParameters, port: port, host: host );

    _printToLog('Query : '+queryUri.toString());
    //queryUri = new Uri.http( path, param);
    return queryUri.toString();
  }


  String getQueryString(Map params, {String prefix: '&', bool inRecursion: false}) {

    String query = '';

    params.forEach((key, value) {

      if (inRecursion) {
        key = '[$key]';
      }

      //if (value is String || value is int || value is double || value is bool) {
      query += '$prefix$key=$value';
      //} else if (value is List || value is Map) {
      // if (value is List) value = value.asMap();
      // value.forEach((k, v) {
      //  query += getQueryString({k: v}, prefix: '$prefix$key', inRecursion: true);
      //});
      // }
    });

    return query;
  }

  /// Make a custom get request to a Woocommerce endpoint, using WooCommerce SDK.

  Future<dynamic> get(String endPoint) async {
    String url = this._getOAuthURL("GET", endPoint);
    String _token = await _localDbService.getSecurityToken();
    String _bearerToken = "Bearer $_token";
    _printToLog('this is the bearer token : '+_bearerToken);
    Map<String, String> headers = new HashMap();
    headers.putIfAbsent('Accept', () => 'application/json charset=utf-8');
    // 'Authorization': _bearerToken,
    try {
      final http.Response response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      _handleHttpError(response);
    } on SocketException {
      throw Exception('No Internet connection.');
    }
  }

  Future<dynamic> oldget(String endPoint) async {
    String url = this._getOAuthURL("GET", endPoint);

    http.Client client = http.Client();
    http.Request request = http.Request('GET', Uri.parse(url));
    request.headers[HttpHeaders.contentTypeHeader] =
    'application/json; charset=utf-8';
    //request.headers[HttpHeaders.authorizationHeader] = _token;
    request.headers[HttpHeaders.cacheControlHeader] = "no-cache";
    String response =
    await client.send(request).then((res) => res.stream.bytesToString());
    var dataResponse = await json.decode(response);
    _handleError(dataResponse);
    return dataResponse;
  }

  /// Make a custom post request to Woocommerce, using WooCommerce SDK.

  Future<dynamic> post(String endPoint, Map data,) async {
    String url = this._getOAuthURL("POST", endPoint);
print(url);
    http.Client client = http.Client();
    http.Request request = http.Request('POST', Uri.parse(url));
    request.headers[HttpHeaders.contentTypeHeader] =
    'application/json; charset=utf-8';
    //request.headers[HttpHeaders.authorizationHeader] = _bearerToken;
    request.headers[HttpHeaders.cacheControlHeader] = "no-cache";
    request.body = json.encode(data);
    print(data);
    String response =
    await client.send(request).then((res) => res.stream.bytesToString());
    var dataResponse = await json.decode(response);

    print('response is below');
    print(dataResponse);
    _handleError(dataResponse);
    return dataResponse;
  }

  /// Make a custom put request to Woocommerce, using WooCommerce SDK.

  Future<dynamic> put(String endPoint, Map data) async {
    String url = this._getOAuthURL("PUT", endPoint);

    http.Client client = http.Client();
    http.Request request = http.Request('PUT', Uri.parse(url));
    request.headers[HttpHeaders.contentTypeHeader] =
    'application/json; charset=utf-8';
    request.headers[HttpHeaders.cacheControlHeader] = "no-cache";
    request.body = json.encode(data);
    String response =
    await client.send(request).then((res) => res.stream.bytesToString());
    var dataResponse = await json.decode(response);
    _handleError(dataResponse);
    return dataResponse;
  }

  /// Make a custom delete request to Woocommerce, using WooCommerce SDK.

  Future<dynamic> Oldelete(String endPoint, Map data) async {
    String url = this._getOAuthURL("DELETE", endPoint);

    http.Client client = http.Client();
    http.Request request = http.Request('DELETE', Uri.parse(url));
    request.headers[HttpHeaders.contentTypeHeader] =
    'application/json; charset=utf-8';
    //request.headers[HttpHeaders.authorizationHeader] = _urlHeader['Authorization'];
    request.headers[HttpHeaders.cacheControlHeader] = "no-cache";
    request.body = json.encode(data);
    final response =
    await client.send(request).then((res) => res.stream.bytesToString());
    _printToLog("this is the delete's response : "+response.toString());
    var dataResponse = await json.decode(response);
    _handleHttpError(dataResponse);
    return dataResponse;
  }


  Future<dynamic> delete(String endPoint, Map data, {String aUrl}) async {
    String realUrl;
    final url = this._getOAuthURL("DELETE", endPoint);
    if(aUrl == null){
      realUrl = url;
    }else {
      realUrl = url;
    }
    // final url = Uri.parse(baseUrl + "notes/delete");
    final request = http.Request("DELETE", Uri.parse(realUrl));
    request.headers.addAll(<String, String>{
      "Accept": "application/json",
    });
    request.body = jsonEncode(data);
    final response = await request.send();
    if (response.statusCode > 300)
      return Future.error("error: status code ${response.statusCode} ${response.reasonPhrase}");
    final deleteResponse = await response.stream.bytesToString();
    _printToLog("delete response : "+deleteResponse.toString());
    return deleteResponse;
  }

}


class QueryString {
  /// Parses the given query string into a Map.
  static Map parse(String query) {
    RegExp search = RegExp('([^&=]+)=?([^&]*)');
    Map result = Map();

    // Get rid off the beginning ? in query strings.
    if (query.startsWith('?')) query = query.substring(1);

    // A custom decoder.
    decode(String s) => Uri.decodeComponent(s.replaceAll('+', ' '));

    // Go through all the matches and build the result map.
    for (Match match in search.allMatches(query)) {
      result[decode(match.group(1))] = decode(match.group(2));
    }

    return result;
  }
}


class WooCommerceError {
  String code;
  String message;
  Data data;

  WooCommerceError({String code, String message, Data data}) {
    this.code = code;
    this.message = message;
    this.data = data;
  }

  WooCommerceError.fromJson(Map<String, dynamic> json) {
    code = json['code'].toString();
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  @override
  String toString() {
    return "WooCommerce Error!\ncode: $code\nmessage: $message\nstatus: ${data.status}";
  }
}

class Data {
  int _status;

  Data({int status}) {
    this._status = status;
  }

  int get status => _status;

  Data.fromJson(Map<String, dynamic> json) {
    _status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this._status;
    return data;
  }
}
