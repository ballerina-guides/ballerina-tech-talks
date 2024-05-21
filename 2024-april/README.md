# Ballerina Tech Talk - April 2024

_Topic_: **Level Up Your APIs: GraphQL with Ballerina** \
_Date_: 2024-04-25 \
_Presenter_: [@ThisaruGuruge](https://github.com/ThisaruGuruge) \
_Link_: [YouTube](https://www.youtube.com/watch?v=hkOMet6bF70)

## Code Sample: Movie Rating System in Ballerina with GraphQL and MongoDB

> This sample was written using Ballerina Swan Lake Update 9 (2201.9.0)

The code sample used in the tech talk is in the `movie_rating_system` directory.

This is a simple movie rating system implemented using Ballerina, GraphQL, and MongoDB. The system allows users to add movies and rate them. This system demonstrates how to use a MongoDB database and expose it via a GraphQL API using Ballerina.

## Prerequisites

- Download and install [Ballerina](https://ballerina.io/downloads/).
- Download and install [MongoDB](https://www.mongodb.com/try/download/community). (This repo includes a docker-compose file to run MongoDB in a Docker container locally.)
- A code editor; preferably [VS Code](https://code.visualstudio.com/) with [Ballerina extension](https://marketplace.visualstudio.com/items?itemName=wso2.ballerina) installed.

## Implementation

This system consists of the following components:

### Datasource

This system uses a MongoDB database to store movie data. The database connectivity is handled through a separate Ballerina submodule named `datasource`. This submodule contains the MongoDB client and the necessary configurations to connect to the MongoDB database.

### GraphQL API

The GraphQL API is implemented using Ballerina's GraphQL module. The GraphQL API is implemented in the default Ballerina module.

The GraphQL API uses caching and dataloader functionalities to optimize the performance of the system. The caching is used to cache the results of the queries and the dataloader is used to batch and cache the results of the queries. Caching is disabled for the `email` field in the `User` type to demonstrate how to disable caching for specific fields. The dataloader is used to batch the queries to the MongoDB database.

#### Obtaining the GraphQL Schema

This repo uses the code-first approach to define the GraphQL schema. The schema is auto-generated at compile time by the Ballerina GraphQL package. The generated schema can be written to a file by using the Ballerina GraphQL CLI tool. To generate the schema file, move to the root directory of the project and run the following command.

```bash
bal graphql -i service.bal
```

This will generate a `schema_service.graphql` file in the root directory of the project.

## Running the Project

1. Clone the repository by running the following command.

    ```bash
    git clone https://github.com/ThisaruGuruge/movie-rating-system.git
    ```

2. Navigate to the cloned repository.

    ```bash
    cd movie-rating-system
    ```

3. Add the `Config.toml` file to the root directory of the project with the following content. You can change the configurations as needed.

    ```toml
    [movie_rating_system]
    enableGraphiql = true # To enable GraphiQL interface. This should be disabled in a production environment
    enableIntrospection = true # To enable introspection queries. This should be disabled in a production environment
    maxQueryDepth = 15 # maximum depth of a query. This should be reduced to a lower value in a production environment
    initDatabase = true # if true, the database will be initialized with some data

    [movie_rating_system.datasource]
    username = "admin" # MongoDB username
    password = "admin" # MongoDB password
    ```

4. Start the MongoDB server using Docker.

    ```bash
    cd resources/docker
    docker-compose up
    ```

5. Run the Ballerina service.

    ```bash
    bal run
    ```

6. The GraphQL API will be exposed at `http://localhost:9090`. If the GraphiQL is enabled (via the `Config.toml` file), you can access the GraphiQL interface at `http://localhost:9090/graphiql`.

## Sample Operations

### Add a Movie

```graphql
mutation AddMovie($movie: MovieInput!) {
  addMovie(movieInput: $movie) {
    id
    title
  }
}
```

To add a movie, the following variable should be passed.

```json
{
  "movie": {
    "title": "Inception",
    "year": 2010,
    "description": "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
    "directorId": "60f3b3b3b3b3b3b3b3b3b3b3"
  }
}
```

The request should also include the `userId` in the HTTP headers to authenticate the request.

>**Note:** In the GraphiQL client, the HTTP headers can be set under the `header` section.

### Review a Movie

```graphql
mutation ReviewMovie($review: ReviewInput!) {
  reviewMovie(reviewInput: $review) {
    id
  }
}
```

To review a movie, the following variable should be passed.

```json
{
  "review": {
    "score": 4,
    "movieId": "60f3b3b3b3b3b3b3b3b3b3",
    "description": "A great movie!"
  }
}
```

The request should also include the `userId` in the headers to authenticate the request.

### List all the Movies

```graphql
Query GetAllMovies {
    movies {
        title
        year
        rating
    }
}
```

### List all the Movies with Director's Information

```graphql
Query GetAllMoviesWithDirector {
    movies {
        title
        year
        rating
        director {
            name
        }
    }
}
```

### List all the Movies by a Director

```graphql
Query GetMoviesByDirector {
    director(id: "60f3b3b3b3b3b3b3b3b3b3") {
        name
        movies {
            title
            year
        }
    }
}
```

## Observability

This example includes observability support from the built-in observability features in the Ballerina GraphQL package. To enable observability, follow the steps below.

1. Add the following entry to the `Ballerina.toml` file.

    ```toml
    [build-options]
    observabilityIncluded = true
    ```

    >**Note:** This is already enabled in the `Ballerina.toml` file in this repository.

2. Add observability configurations to the `Config.toml` file.

    ```toml
    [ballerina.observe]
    metricsEnabled=true
    metricsReporter="prometheus"
    tracingEnabled=true
    tracingProvider="jaeger"

    [ballerinax.prometheus]
    port=9797
    host="0.0.0.0"

    [ballerinax.jaeger]
    agentHostname="localhost"
    agentPort=4317
    samplerType="const"
    samplerParam=1.0
    reporterFlushInterval=2000
    reporterBufferSize=1000
    ```

    For more information on observability in Ballerina, refer to the [Observe Ballerina Programs](https://ballerina.io/learn/observe-ballerina-programs/) guide.

3. Start the Jaeger backend, Prometheus, and Grafana servers using Docker.

    >**Note:** This repository includes a `docker-compose` file to start the Jaeger backend, Prometheus, and Grafana servers in the same `docker-compose` file with the `observability` network.
