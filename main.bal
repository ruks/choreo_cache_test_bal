import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerinax/redis;

configurable string redisHost = ?;
configurable int redisPort = ?;
configurable string redisPassword = ?;
configurable int pingInterval = ?;

redis:SecureSocket redisSecureSocket = {
    verifyMode: redis:FULL
};

redis:ConnectionConfig redisConfig = {
    connection: {
        host: redisHost,
        port: redisPort,
        username: "default",
        password: redisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true,
    secureSocket: redisSecureSocket
};

final redis:Client redisClient = check new (redisConfig);

listener http:Listener httpListener = check new (2020);

http:Service s = service object {
    isolated resource function get cache\-item() returns http:Ok|http:InternalServerError {
        string message = "Hello, World!";
        string?|error cachedMessage = redisClient->get("hello");
        if cachedMessage is error {
            log:printError("Error getting cache key", cachedMessage);
        } else if cachedMessage is () {
            log:printInfo("Cache miss");
            string|error? setError = redisClient->set("hello", "Hello, World!, Cached");
            if setError is error {
                log:printError("Error setting cache key", setError);
            }
        } else {
            message = <string>cachedMessage;
            log:printInfo("Cache hit");
        }
        return <http:Ok>{
            body: message
        };
    }
};

public function main() returns error? {
    log:printInfo("Starting Redis ping loop (every 10s) and HTTP listener…");

    // Start the HTTP listener in the background
    check httpListener.attach(s, "/");
    check httpListener.start();

    if pingInterval == 0 {
        log:printInfo("PING_INTERVAL=0, skipping Redis ping loop.");
        return;
    }
    // Ping loop
    while true {
        string|error res = redisClient->ping();
        if res is error {
            log:printError("Redis ping failed", res);
        } else {
            log:printInfo("Redis ping response: " + res);
        }
        // Sleep for 10 seconds
        runtime:sleep(<decimal>pingInterval);
    }
}
