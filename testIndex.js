function verifyJwt() {
  let jwt = require("jsonwebtoken");
  let secret = "some-secret";
  // ruleid: jwt-none-alg
  jwt.verify(
    "token-here",
    secret,
    { algorithms: ["RS256", "none"] },
    function (err, payload) {
      console.log(payload);
    }
  );
  var password = "AaJj123456";
}
