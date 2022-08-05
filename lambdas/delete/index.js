var AWS = require('aws-sdk');
AWS.config.update({region: 'us-east-1'});


exports.handler = async (event) => {
    var ddb = new AWS.DynamoDB();
    let response
    try {
      let eventObj = JSON.parse(event.body)
      var params = {
        TableName: 'user-data',
        Key: {
          'userID': {S: eventObj.userID}
        }
      };
    } catch(err) {
      response = {
        statusCode: 500,
          body: JSON.stringify("Bad / Incomplete Data Provided"),
      }
      return response
    }

    try {
        const data = await ddb.deleteItem(params).promise();
        response = {
          statusCode: 200,
          body: JSON.stringify('Record Deleted!'),
        };
             
    } catch (err) {
      console.log(err, err.stack);
      response = {
          statusCode: 500,
          body: JSON.stringify(err),
        };
    }
    return response; 
};