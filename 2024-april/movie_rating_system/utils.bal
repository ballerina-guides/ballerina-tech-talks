import ballerina/graphql;
import ballerina/graphql.dataloader;
import ballerina/http;
import ballerina/log;

const string DATASOURCE = "datasource";
const string USER = "user";
const string USER_ID = "userId";

isolated function loadDirectors(readonly & anydata[] ids) returns DirectorRecord[]|error {
    string[] keys = check ids.ensureType();
    stream<DirectorRecord, error?> directorStream = check datasource->getDirectorsById(keys);
    DirectorRecord[] directors = check from DirectorRecord director in directorStream
        select director;

    DirectorRecord[] result = [];
    foreach [int, string] [i, id] in keys.enumerate() {
        foreach DirectorRecord director in directors {
            if id == director.id {
                result[i] = director;
                break;
            }
        }
    }
    return result;
}

isolated function loadMovies(readonly & anydata[] ids) returns MovieRecord[][]|error {
    string[] keys = check ids.ensureType();
    stream<MoviesOfDirector, error?> movieStream = check datasource->getMoviesByDirectorId(keys);
    MoviesOfDirector[] moviesWithDirectorId = check from MoviesOfDirector movieSet in movieStream
        select movieSet;
    MovieRecord[][] result = [];

    foreach [int, string] [i, key] in keys.enumerate() {
        foreach MoviesOfDirector movieSet in moviesWithDirectorId {
            if key == movieSet._id {
                result[i] = movieSet.movies;
                break;
            }
        }
    }
    return result;
}

isolated function validateUserRole(graphql:Context context, string expectedRole) returns error? {
    UserRecord? user = check context.get(USER).ensureType();
    if user is () {
        return error("Authentication error: Invalid user");
    }
    if user.roles.indexOf(expectedRole) !is int {
        return error("Authorization error: Insufficient permissions");
    }
}

isolated function initContext(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
    graphql:Context context = new;
    context.set(DATASOURCE, datasource);

    string|http:HeaderNotFoundError userId = request.getHeader(USER_ID);
    if userId is http:HeaderNotFoundError {
        context.set(USER, ());
    } else {
        UserRecord|error user = datasource->getUser(userId);
        if user is error {
            log:printError("User not found", user);
            return error("User not found");
        }
        context.set(USER, user);
        context.set(USER_ID, userId);
    }
    context.registerDataLoader(DIRECTOR_LOADER, new dataloader:DefaultDataLoader(loadDirectors));
    context.registerDataLoader(MOVIE_LOADER, new dataloader:DefaultDataLoader(loadMovies));
    return context;
}
