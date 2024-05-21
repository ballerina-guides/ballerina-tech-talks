public type Movie record {|
    readonly string id;
    string title;
    int year;
    string description;
    int score = 0;
    int reviewers = 0;
    readonly string directorId;
|};

public type Director record {|
    readonly string id;
    string name;
    string bio;
|};

public type User record {|
    readonly string id;
    string name;
    string email;
    string[] roles;
|};

public type Review record {|
    readonly string id;
    string description;
    int score;
    readonly string movieId;
    readonly string userId;
|};

type MovieScore record {|
    string _id;
    int score;
    int reviewers;
|};
