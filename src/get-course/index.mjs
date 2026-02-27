import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  let id = event.pathParameters?.id || event.queryStringParameters?.id;

  if (!id && event.body) {
    try {
      const body =
        typeof event.body === "string" ? JSON.parse(event.body) : event.body;
      id = body.id;
    } catch (e) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid JSON body" }),
      };
    }
  }

  if (!id) {
    id = event.id;
  }

  if (!id) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Missing required field: id" }),
    };
  }

  try {
    const response = await docClient.send(
      new GetCommand({
        TableName: process.env.TABLE_NAME,
        Key: { id: id },
      }),
    );

    if (!response.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: "Course not found" }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify(response.Item),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: err.message }),
    };
  }
};
