import movie_rating_system.datasource;

import ballerina/constraint;
import ballerina/graphql;
import ballerina/graphql.dataloader;

const string DIRECTOR_LOADER = "directorLoader";
const string MOVIE_LOADER = "movieLoader";

# Represents a Movie in the movie database.
@display {
    label: "Movie",
    id: "movie"
}
isolated service class Movie {
    private final string id;
    private final string title;
    private final int year;
    private final string description;
    private final int score;
    private final int reviewers;
    private final string directorId;

    isolated function init(MovieRecord movieRecord) {
        self.id = movieRecord.id;
        self.title = movieRecord.title;
        self.year = movieRecord.year;
        self.description = movieRecord.description;
        self.score = movieRecord.score;
        self.reviewers = movieRecord.reviewers;
        self.directorId = movieRecord.directorId;
    }

    # The ID of the movie.
    # + return - ID of the movie.
    isolated resource function get id() returns @graphql:ID string => self.id;

    # The title of the movie.
    # + return - Title of the movie.
    isolated resource function get title() returns string => self.title;

    # The year the movie was released.
    # + return - Year the movie was released.
    isolated resource function get year() returns int => self.year;

    # The description of the movie.
    # + return - Description of the movie.
    isolated resource function get description() returns string => self.description;

    # The average rating of the movie.
    # + return - Average rating of the movie.
    isolated resource function get rating() returns float? {
        if self.score == 0 || self.reviewers == 0 {
            return 0.0;
        }
        return (<float>self.score / <float>self.reviewers).round(2);
    }

    isolated function preDirector(graphql:Context context) {
        dataloader:DataLoader directorLoader = context.getDataLoader(DIRECTOR_LOADER);
        directorLoader.add(self.directorId);
    }

    # The director of the movie.
    # + return - Director of the movie.
    isolated resource function get director(graphql:Context context) returns Director|error? {
        dataloader:DataLoader directorLoader = context.getDataLoader(DIRECTOR_LOADER);
        DirectorRecord directorRecord = check directorLoader.get(self.directorId);
        return new (directorRecord);
    }
}

# Represents a Director in the movie database.
@display {
    label: "Director",
    id: "director"
}
public isolated service class Director {
    private final string id;
    private final string name;
    private final string bio;

    isolated function init(DirectorRecord directorRecord) {
        self.id = directorRecord.id;
        self.name = directorRecord.name;
        self.bio = directorRecord.bio;
    }

    # The ID of the director.
    # + return - ID of the director.
    isolated resource function get id() returns @graphql:ID string => self.id;

    # The name of the director.
    # + return - Name of the director.
    isolated resource function get name() returns string => self.name;

    # The biography of the director.
    # + return - Biography of the director.
    isolated resource function get bio() returns string => self.bio;

    isolated function preMovies(graphql:Context context) {
        dataloader:DataLoader movieLoader = context.getDataLoader(MOVIE_LOADER);
        movieLoader.add(self.id);
    }

    # The movies directed by the director.
    # + return - Movies directed by the director.
    isolated resource function get movies(graphql:Context context) returns Movie[]|error? {
        dataloader:DataLoader movieLoader = context.getDataLoader(MOVIE_LOADER);
        MovieRecord[] movieRecords = check movieLoader.get(self.id);
        return from MovieRecord movieRecord in movieRecords
            select new (movieRecord);
    }
}

# Represents a User in the movie database.
@display {
    label: "User",
    id: "user"
}
public isolated service class User {
    private final string id;
    private final string name;
    private final string email;

    isolated function init(UserRecord userRecord) {
        self.id = userRecord.id;
        self.name = userRecord.name;
        self.email = userRecord.email;
    }

    # The ID of the user.
    # + return - ID of the user.
    isolated resource function get id() returns @graphql:ID string => self.id;

    # The name of the user.
    # + return - Name of the user.
    isolated resource function get name() returns string? => self.name;

    # The email of the user.
    # + return - Email of the user.
    @graphql:ResourceConfig {
        cacheConfig: {
            enabled: false
        },
        interceptors: new AdminAuthInterceptor()
    }
    isolated resource function get email(graphql:Context context) returns string? => self.email;
}

# Represents a Review in the movie database.
@display {
    label: "Review",
    id: "review"
}
public isolated service class Review {
    private final string id;
    private final string userId;
    private final string movieId;
    private final int score;
    private final string description;

    isolated function init(ReviewRecord reviewRecord) {
        self.id = reviewRecord.id;
        self.userId = reviewRecord.userId;
        self.movieId = reviewRecord.movieId;
        self.score = reviewRecord.score;
        self.description = reviewRecord.description;
    }

    # The ID of the review.
    # + return - ID of the review.
    isolated resource function get id() returns @graphql:ID string => self.id;

    # The user who wrote the review.
    # + return - User who wrote the review.
    isolated resource function get user(graphql:Context context) returns User|error? {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        UserRecord userRecord = check datasource->getUser(self.userId);
        return new (userRecord);
    }

    # The movie that was reviewed.
    # + return - Movie that was reviewed.
    isolated resource function get movie(graphql:Context context) returns Movie|error? {
        datasource:Datasource datasource = check context.get(DATASOURCE).ensureType();
        MovieRecord movieRecord = check datasource->getMovieById(self.movieId);
        return new (movieRecord);
    }

    # The score given by the user.
    # + return - Score given by the user.
    isolated resource function get score() returns int => self.score;

    # The description of the review.
    # + return - Description of the review.
    isolated resource function get description() returns string => self.description;
}

type MovieRecord record {|
    readonly string id;
    string title;
    int year;
    string description;
    int score = 0; // Total review points
    int reviewers = 0;
    readonly string directorId;
|};

type DirectorRecord record {|
    readonly string id;
    string name;
    string bio;
|};

type UserRecord record {|
    readonly string id;
    string name;
    string email;
    string[] roles;
|};

type ReviewRecord record {|
    readonly string id;
    readonly string userId;
    readonly string movieId;
    int score;
    string description;
|};

# Input type for adding a Movie Review.
@display {
    label: "Review Input",
    id: "review-input"
}
public type ReviewInput record {|
    # ID of the movie
    @graphql:ID
    string movieId;

    # Score given by the user. Should be between 1 and 5.
    @constraint:Int {
        minValue: 1,
        maxValue: 5
    }
    int score;

    # Description of the review.
    string description;
|};

# Input type for adding a Movie.
@display {
    label: "Movie Input",
    id: "movie-input"
}
public type MovieInput record {|
    # Title of the movie
    string title;

    # Year the movie was released
    int year;

    # Description of the movie
    string description;

    # ID of the director
    @graphql:ID
    string directorId;
|};

# Input type for adding a Director.
@display {
    label: "Director Input",
    id: "director-input"
}
public type DirectorInput record {|
    # Name of the director
    string name;

    # Biography of the director
    string bio;
|};

type MoviesOfDirector record {|
    string _id;
    MovieRecord[] movies;
|};

readonly service class AdminAuthInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        check validateUserRole(context, "admin");
        return context.resolve('field);
    }
}

readonly service class UserAuthInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        check validateUserRole(context, "user");
        return context.resolve('field);
    }
}
