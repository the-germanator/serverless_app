var AWS = require('aws-sdk');
AWS.config.update({region: 'us-east-1'});


exports.handler = async (event) => {
    var ddb = new AWS.DynamoDB();
    let response
    try {
      let eventObj = JSON.parse(event.body)
      var params = {
        TableName: 'user-data',
        Item: {
          'userID': { S: eventObj.userID},
          'userData' : {M: {
              'firstName': {S: eventObj.firstName},
              'lastName': {S: eventObj.lastName}
          }}
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
        const data = await ddb.putItem(params).promise();
        response = {
          statusCode: 200,
          body: JSON.stringify('Record Inserted!'),
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