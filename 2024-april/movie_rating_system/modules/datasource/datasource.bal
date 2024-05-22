import ballerina/io;
import ballerina/log;
import ballerinax/mongodb;

configurable string username = ?;
configurable string password = ?;

public isolated client class Datasource {

    private final mongodb:Client mongoClient;
    private final mongodb:Database db;

    private final mongodb:Collection moviesCollection;
    private final mongodb:Collection directorsCollection;
    private final mongodb:Collection usersCollection;
    private final mongodb:Collection reviewsCollection;

    public isolated function init(boolean initDatabase = false) returns error? {
        self.mongoClient = check new (connection = string `mongodb://${username}:${password}@localhost:27017/admin`);
        mongodb:Database db = check self.mongoClient->getDatabase("movie_rating_system");
        check db->drop();
        self.db = check self.mongoClient->getDatabase("movie_rating_system");

        self.moviesCollection = check self.db->getCollection("movies");
        self.directorsCollection = check self.db->getCollection("directors");
        self.usersCollection = check self.db->getCollection("users");
        self.reviewsCollection = check self.db->getCollection("reviews");

        if initDatabase {
            check self.initDatabase();
        }
    }

    isolated function initDatabase() returns error? {
        check self->initDirectors();
        check self->initUsers();
        check self->initReviews();
        check self->initMovies();
        check self->updateReviews();
    }

    isolated remote function initMovies() returns error? {
        json moviesData = check io:fileReadJson("resources/db/movies.json");
        if moviesData is map<json> {
            Movie[] movies = check moviesData["movies"].fromJsonWithType();
            error? result = self.moviesCollection->insertMany(movies);
            if result == () {
                return;
            }
            logError("Failed to insert movies", result);
            return;
        }
        return error("Error in reading movies.json");
    }

    isolated remote function initDirectors() returns error? {
        json directorsData = check io:fileReadJson("resources/db/directors.json");
        if directorsData is map<json> {
            Director[] directors = check directorsData["directors"].fromJsonWithType();
            error? result = self.directorsCollection->insertMany(directors);
            if result == () {
                return;
            }
            logError("Failed to insert directors", result);
            return;
        }
        return error("Error in reading directors.json");
    }

    isolated remote function initUsers() returns error? {
        json usersData = check io:fileReadJson("resources/db/users.json");
        if usersData is map<json> {
            User[] users = check usersData["users"].fromJsonWithType();
            error? result = self.usersCollection->insertMany(users);
            if result == () {
                return;
            }
            logError("Failed to insert users", result);
        }
        return error("Error in reading users.json");
    }

    isolated remote function initReviews() returns error? {
        json reviewsData = check io:fileReadJson("resources/db/reviews.json");
        if reviewsData is map<json> {
            Review[] reviews = check reviewsData["reviews"].fromJsonWithType();
            error? result = self.reviewsCollection->insertMany(reviews);
            if result == () {
                return;
            }
            logError("Failed to insert reviews", result);
        }
        return error("Error in reading reviews.json");
    }

    isolated remote function updateReviews() returns error? {
        stream<MovieScore, error?> movies = check self.reviewsCollection->aggregate([
            {
                \$group: {
                    _id: "$movieId",
                    score: {
                        \$sum: "$score"
                    },
                    reviewers: {
                        \$sum: 1
                    }
                }
            },
            {
                \$project: {
                    movieId: "$movieId",
                    score: "$score",
                    reviewers: "$reviewers"
                }
            }
        ]);
        MovieScore[] movieScores = check from MovieScore movie in movies
            select movie;
        foreach MovieScore movieScore in movieScores {
            mongodb:UpdateResult result = check self.moviesCollection->updateOne({
                id: movieScore._id
            },
            {
                set: {
                    score: movieScore.score,
                    reviewers: movieScore.reviewers
                }
            });
            if result.modifiedCount != 1 {
                error err = error("Failed to update the movie score");
                logError("Update failed", err);
            }
        }
    }

    isolated remote function getMovies() returns stream<Movie, error?>|error {
        stream<Movie, error?>|mongodb:Error movies = self.moviesCollection->find();
        if movies is mongodb:ApplicationError {
            logError("Failed to retrieve the movies", movies);
            return error("Failed to retrieve the movies");
        } else if movies is mongodb:DatabaseError {
            logError("MongoDB server error occurred", movies);
            return error("MongoDB server error occurred");
        }
        return movies;
    }

    isolated remote function getMovieById(string id) returns Movie|error {
        Movie? movie = check self.moviesCollection->findOne({id});
        if movie is Movie {
            return movie;
        }
        return error(string `Movie not found for the id: ${id}`);
    }

    isolated remote function addMovie(Movie movie) returns Movie|error {
        check self.moviesCollection->insertOne(movie);
        return movie;
    }

    isolated remote function getDirectors() returns stream<Director, error?>|error {
        stream<Director, error?>|mongodb:Error directors = self.directorsCollection->find();
        if directors is mongodb:ApplicationError {
            logError("Failed to retrieve the directors", directors);
            return error("Failed to retrieve the directors");
        } else if directors is mongodb:DatabaseError {
            logError("MongoDB server error occurred", directors);
            return error("MongoDB server error occurred");
        }
        return directors;
    }

    isolated remote function getDirector(string id) returns Director|error {
        Director? director = check self.directorsCollection->findOne({id});
        if director is Director {
            return director;
        }
        return error(string `Director not found for the id: ${id}`);
    }

    isolated remote function getMoviesByDirectorId(string[] ids) returns stream<record {|string _id; Movie[] movies;|}, error?>|error {
        map<json>[] pipeline = [
            {
                \$group: {
                    _id: "$directorId",
                    movies: {
                        \$push: {
                            id: "$id",
                            title: "$title",
                            year: "$year",
                            description: "$description",
                            score: "$score",
                            reviewers: "$reviewers",
                            directorId: "$directorId"
                        }
                    }
                }
            },
            {
                \$match: {
                    "movies.directorId": {
                        \$in: ids
                    }
                }
            },
            {
                \$sort: {
                    "movies.directorId": 1
                }
            }
        ];
        stream<record {|string _id; Movie[] movies;|}, error?>|mongodb:Error movies = self.moviesCollection->aggregate(pipeline);
        if movies is mongodb:Error {
            if movies is mongodb:ApplicationError {
                logError("Failed to retrieve the movies", movies);
                return error("Failed to retrieve the movies");
            } else if movies is mongodb:DatabaseError {
                logError("MongoDB server error occurred", movies);
                return error("MongoDB server error occurred");
            }
            logError("Unexpected error occurred while retrieving the movies", movies);
            return movies;
        }
        return from record {|string _id; Movie[] movies;|} movieSet in movies
            select movieSet;
    }

    isolated remote function getDirectorById(string id) returns Director|error {
        Director? director = check self.directorsCollection->findOne({id});
        if director is Director {
            return director;
        }
        return error(string `Director not found for the id: ${id}`);
    }

    isolated remote function getDirectorsById(string[] ids) returns stream<Director, error?>|error {
        stream<Director, error?>|mongodb:Error directors = self.directorsCollection->find({id: {\$in: ids}});
        if directors is mongodb:ApplicationError {
            logError("Failed to retrieve the directors", directors);
            return error("Failed to retrieve the directors");
        } else if directors is mongodb:DatabaseError {
            logError("MongoDB server error occurred", directors);
            return error("MongoDB server error occurred");
        }
        return directors;
    }

    isolated remote function addDirector(Director director) returns Director|error {
        check self.directorsCollection->insertOne(director);
        return director;
    }

    isolated remote function getUsers() returns stream<User, error?>|error {
        stream<User, error?>|mongodb:Error users = self.usersCollection->find({}, {}, {
            _id: 0,
            id: 1,
            name: 1,
            email: 1,
            roles: 1
        });
        if users is mongodb:ApplicationError {
            logError("Failed to retrieve the users", users);
            return error("Failed to retrieve the users");
        } else if users is mongodb:DatabaseError {
            logError("MongoDB server error occurred", users);
            return error("MongoDB server error occurred");
        }
        return users;
    }

    isolated remote function getUser(string id) returns User|error {
        User? user = check self.usersCollection->findOne({
            id: id
        }, projection = {
            _id: 0,
            id: 1,
            name: 1,
            email: 1,
            roles: 1
        });
        if user is User {
            return user;
        }
        return error(string `User not found for the id: ${id}`);
    }

    isolated remote function addReview(Review review) returns Review|error {
        Movie? movie = check self.moviesCollection->findOne({id: review.movieId});
        if movie is Movie {
            int score = movie.score + review.score;
            int reviewers = movie.reviewers + 1;
            mongodb:UpdateResult result = check self.moviesCollection->updateOne({id: review.movieId}, {
                set: {
                    score,
                    reviewers
                }
            });
            if result.modifiedCount == 1 {
                return review;
            }
            check self.reviewsCollection->insertOne(review);
        }
        return error("Failed to add the review");
    }
}

isolated function logWarn(string message) {
    log:printInfo(string `[WARN]: ${message}`);
}

isolated function logError(string message, error err) {
    log:printError(string `[ERROR]: ${message}`, err);
}
