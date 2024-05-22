import movie_rating_system.datasource;

import ballerina/graphql;
import ballerina/log;
import ballerina/uuid;
import ballerinax/jaeger as _;
import ballerinax/prometheus as _;

configurable boolean enableGraphiql = false;
configurable boolean enableIntrospection = false;
configurable int maxQueryDepth = 4;
configurable boolean initDatabase = true;

final datasource:Datasource datasource = check new (initDatabase);

@display {
    label: "Movie Rating System",
    id: "movie-rating-system"
}
@graphql:ServiceConfig {
    graphiql: {
        enabled: enableGraphiql
    },
    introspection: enableIntrospection,
    maxQueryDepth,
    contextInit: initContext,
    cacheConfig: {
        enabled: true
    }
}
service on new graphql:Listener(9091) {

    # Returns the list of movies in the database.
    # + return - List of movies
    resource function get movies(graphql:Context context) returns Movie[]|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        stream<MovieRecord, error?> movieStream = check datasource->getMovies();
        return from MovieRecord movieRecord in movieStream
            select new (movieRecord);
    }

    # Returns the list of users in the database.
    # + return - List of users
    @graphql:ResourceConfig {
        interceptors: new UserAuthInterceptor()
    }
    resource function get users(graphql:Context context) returns User[]|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        stream<UserRecord, error?> userStream = check datasource->getUsers();
        return from UserRecord userRecord in userStream
            select new (userRecord);
    }

    # Returns the list of directors in the database.
    # + return - List of directors
    resource function get directors(graphql:Context context) returns Director[]|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        stream<DirectorRecord, error?> directorStream = check datasource->getDirectors();
        return from DirectorRecord directorRecord in directorStream
            select new (directorRecord);
    }

    # Returns the Director with the given ID.
    # + id - The ID of the director
    # + return - The director with the given ID
    resource function get director(graphql:Context context, @graphql:ID string id) returns Director|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        DirectorRecord|error directorRecord = datasource->getDirector(id);
        if directorRecord is error {
            return error("Director not found");
        }
        return new (directorRecord);
    }

    # Adds a new review to the database.
    # + context - The GraphQL context
    # + reviewInput - The input values for the review
    # + return - The added review
    @graphql:ResourceConfig {
        interceptors: new UserAuthInterceptor()
    }
    remote function addReview(graphql:Context context, ReviewInput reviewInput) returns Review|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        string userId = check context.get(USER_ID).ensureType();
        ReviewRecord reviewRecord = {
            id: uuid:createRandomUuid(),
            userId,
            ...reviewInput
        };
        ReviewRecord|error result = datasource->addReview(reviewRecord);
        if result is error {
            log:printError("Failed to add the review", result);
            return error("Failed to add the review");
        }
        check context.invalidate("reviews");
        return new (result);
    }

    # Adds a new movie to the database.
    # + context - The GraphQL context
    # + movieInput - The input values for the movie
    # + return - The added movie
    @graphql:ResourceConfig {
        interceptors: new UserAuthInterceptor()
    }
    remote function addMovie(graphql:Context context, MovieInput movieInput) returns Movie|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        MovieRecord movieRecord = {
            id: uuid:createRandomUuid(),
            ...movieInput
        };
        MovieRecord|error result = datasource->addMovie(movieRecord);
        if result is error {
            log:printError("Failed to add the movie", result);
            return error("Failed to add the movie");
        }
        check context.invalidate("movies");
        return new (result);
    }

    # Adds a new director to the database.
    # + context - The GraphQL context
    # + directorInput - The input values for the director
    # + return - The added director
    @graphql:ResourceConfig {
        interceptors: new UserAuthInterceptor()
    }
    remote function addDirector(graphql:Context context, DirectorInput directorInput) returns Director|error {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        DirectorRecord directorRecord = {
            id: uuid:createRandomUuid(),
            ...directorInput
        };
        DirectorRecord|error result = datasource->addDirector(directorRecord);
        if result is error {
            log:printError("Failed to add the director", result);
            return error("Failed to add the director");
        }
        check context.invalidate("directors");
        return new (result);
    }
}
