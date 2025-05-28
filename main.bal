import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerinax/redis;

configurable string redisHost = "valkey-aca47945a34b44d281f98ba5876d9396-redis11497295657-choreo.h.aivencloud.com";
configurable int redisPort = 12079;
configurable string redisPassword = os:getEnv("REDIS_PASS");

redis:SecureSocket redisSecureSocket = {
    verifyMode: redis:FULL
};

redis:ConnectionConfig redisConfig = {
    connection: {
        host: redisHost,
        port: redisPort,
        password: redisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true,
    secureSocket: redisSecureSocket
};

redis:Client redisClient = check new (redisConfig);

listener http:Listener httpListener = check new (2020);

service / on httpListener {
    resource function get cache\-item() returns http:Ok|http:InternalServerError {
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
}
