var AWS = require('aws-sdk');
AWS.config.update({region: 'us-east-1'});


exports.handler = async (event) => {
    var ddb = new AWS.DynamoDB();
    let response
    try {
      let eventObj = event.queryStringParameters
      console.log(eventObj)
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
        const data = await ddb.getItem(params).promise();
        const jsonData = AWS.DynamoDB.Converter.unmarshall(data.Item)
        console.log(jsonData)
        response = {
          statusCode: 200,
          body: JSON.stringify(jsonData),
        };
             
    } catch (err) {
      console.log(err, err.stack);
      console.log('ERROR')
      response = {
          statusCode: 500,
          body: JSON.stringify(err),
        };
    }
    return response; 
};