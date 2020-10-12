
class WooCustomer {
  int id;
 /* String dateCreated;
  String dateCreatedGmt;
  String dateModified;
  String dateModifiedGmt;
    String role;
  */
  String email;
  String firstName;
  String lastName;
  String username;
  String password;
  //Billing billing;
  //Shipping shipping;
//  bool isPayingCustomer;
//  String avatarUrl;
//  List<WooCustomerMetaData> metaData;
 // Links links;

  WooCustomer(
      {this.id,
      /*  this.dateCreated,
        this.dateCreatedGmt,
        this.dateModified,
        this.dateModifiedGmt,
        this.role,*/
        this.email,
        this.firstName,
        this.lastName,
        this.username,
        this.password,
       // this.billing,
        //this.shipping,
       // this.isPayingCustomer,
     //   this.avatarUrl,
     //   this.metaData,
        //this.links
  });

  WooCustomer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
   /* dateCreated = json['date_created'];
    dateCreatedGmt = json['date_created_gmt'];
    dateModified = json['date_modified'];
    dateModifiedGmt = json['date_modified_gmt'];

    role = json['role'];
    username = json['username'];
    metaData =
        (json['meta_data'] as List).map((i) => WooCustomerMetaData.fromJson(i)).toList();*/
    email = json['email'];
    firstName = json['first_name'];
    lastName = json['last_name'];
   /* billing =
    json['billing'] != null ? new Billing.fromJson(json['billing']) : null;
    shipping = json['shipping'] != null
        ? new Shipping.fromJson(json['shipping'])
        : null;
    isPayingCustomer = json['is_paying_customer'];
    avatarUrl = json['avatar_url'];

    links = json['_links'] != null ? new Links.fromJson(json['_links']) : null;*/
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
  /*  data['date_created'] = this.dateCreated;
    data['date_created_gmt'] = this.dateCreatedGmt;
    data['date_modified'] = this.dateModified;
    data['date_modified_gmt'] = this.dateModifiedGmt;
    data['role'] = this.role;*/
    data['email'] = this.email;
    if (this.firstName != null) {
      data['first_name'] = this.firstName;
    }
    data['last_name'] = this.lastName;
    if (this.lastName != null) {
      data['last_name'] = this.lastName;
    }
    data['username'] = this.username;
    data['password'] = this.password;
   /* if (this.billing != null) {
      data['billing'] = this.billing.toJson();
    }
    if (this.shipping != null) {
      data['shipping'] = this.shipping.toJson();
    }
    data['is_paying_customer'] = this.isPayingCustomer;
    data['avatar_url'] = this.avatarUrl;
    if (this.metaData != null) {
      data['meta_data'] = this.metaData.map((v) => v.toJson()).toList();
    }
    if (this.links != null) {
      data['_links'] = this.links.toJson();
    }?*/
    return data;
  }
  @override toString() => this.toJson().toString();
}

class WooCustomerMetaData {
  final int id;
  final String key;
  final String value;

  WooCustomerMetaData(this.id, this.key, this.value);

  WooCustomerMetaData.fromJson(Map<String, dynamic> json)
      : id = json['name'],
        key = json['email'],
        value = json['value'];

  Map<String, dynamic> toJson() => {'id': id, 'key': key, 'value': value};
}