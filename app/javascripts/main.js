var MongoClient = require('mongodb').MongoClient;
var url = "mongodb://localhost:27017/";
MongoClient.connect(url, function(err, db) {   //here db is the client obj
    if (err) throw err;
    var dbase = db.db("mydb"); //here
    var products = dbase.collection('products');
    products.find({}).toArray(function (err,data) {
        //nếu lỗi
        if (err) throw err;
        //nếu thành công
        console.log(data);
  });
    db.close();
});
