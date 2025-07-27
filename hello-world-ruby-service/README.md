# Hello World Ruby

Sample for Hello World service. This API responds with a "Hello World" message when called, making it an excellent starting point for beginners and a handy tool for testing APIs with Ruby.

This service now includes an AWS Cognito JWT Authentication endpoint (`/auth`) that authenticates users against AWS Cognito and returns an ID token.

### Prerequisites
1. Fork the repositoy

## Getting started

You can deploy this application to Choreo using either buildpacks or the provided Dockerfile.

### Option 1: Deploy with Buildpacks

Please refer to the Choreo documentation under the [Develop an Application with Buildpacks](https://wso2.com/choreo/develop-components/deploy-an-application-with-buildpacks) to learn how to deploy the application.

### Option 2: Deploy with Dockerfile

To deploy using the provided Dockerfile:

1. In the Choreo console, create a new Service component
2. Select 'Docker' as the build method
3. Connect your GitHub repository
4. Specify the Dockerfile path as `hello-world-ruby-service/Dockerfile`
5. Configure the required environment variables in Choreo (see Configuration section)

1. Select `Service` Card from Component Creation Wizard
2. Select `Ruby` as the buildpack. Fill as follow according to selected Buildpack.

    | **Field**             | **Description**                               |
    |-----------------------|-----------------------------------------------|
    |Name           | Hello World Ruby WebApp              |
    |Description    | Hello World Ruby WebApp       |
    | **GitHub Account**    | Your account                                  |
    | **GitHub Repository** | choreo-samples |
    | **Branch**            | **`main`**                               |
    | **Buildpack**      | Ruby|
    | **Select Go Project Directory**       | hello-world-ruby-webapp |
    | **Select Language Version**              | 3.1.x |

3. Click Create. Once the component creation is complete, you will see the component overview page.
4. Deploy the created component

## AWS Cognito Authentication Endpoint

This service includes an authentication endpoint that authenticates users against AWS Cognito and returns a JWT ID token.

### Configuration

Before using the authentication endpoint, you need to configure AWS Cognito credentials. Copy the `.env.example` file to `.env` and update the following values:

```
AWS_COGNITO_USER_POOL_ID=your_user_pool_id
AWS_COGNITO_CLIENT_ID=your_client_id
AWS_COGNITO_CLIENT_SECRET=your_client_secret  # Optional, only if your app client has a secret
AWS_COGNITO_REGION=your_aws_region
AWS_COGNITO_PROFILE=development  # Optional, for local development with AWS profile
```

### Usage

Send a POST request to `/auth` with the following JSON body:

```json
{
  "auth": {
    "username": "email@example.com",
    "password": "password"
  }
}
```

#### Successful Response

```json
{
  "id_token": "eyJraWQiOiJ..."  // JWT ID token
}
```

#### Error Response

```json
{
  "error": "Invalid username or password."
}
```

### Authentication Flow

1. The client sends username/password to the endpoint
2. The endpoint authenticates against Cognito using the ADMIN_USER_PASSWORD_AUTH flow
3. On success, the ID token is returned to the client
4. The client can use this token for subsequent API requests

### Environment Support

- **Local Development**: Uses the AWS profile specified in the .env file (typically 'development')
- **AWS Environments**: Automatically uses the IAM role attached to the ECS/EC2 instance
- **Choreo Deployment**: Uses environment variables set in Choreo
