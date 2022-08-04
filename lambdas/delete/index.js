var AWS = require('aws-sdk');
AWS.config.update({region: 'us-east-1'});


exports.handler = async (event) => {
    var ddb = new AWS.DynamoDB();
    let response
    if(!event || !event.body || !event.body.userID) {
      response = {
        statusCode: 500,
          body: JSON.stringify("Insufficient Data Provided"),
      }
      return response
    }
    var params = {
      TableName: 'user-data',
      Key: {
        'userID': {S: event.body.userID}
      }
    };

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