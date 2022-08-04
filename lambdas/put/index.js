var AWS = require('aws-sdk');
AWS.config.update({region: 'us-east-1'});


exports.handler = async (event) => {
    var ddb = new AWS.DynamoDB();
    let response
    if(!event || !event.body || !event.body.userID || !event.body.firstName || !event.body.lastName) {
      response = {
        statusCode: 500,
          body: JSON.stringify("Insufficient Data Provided"),
      }
      return response
    }
    var params = {
      TableName: 'user-data',
      Item: {
        'userID': { S: event.body.userID || '' },
        'userData' : {M: {
            'firstName': {S: event.body.firstName || '' },
            'lastName': {S: event.body.lastName || '' }
        }}
      }
    };
    
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