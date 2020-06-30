# Design

## API

Hawk is being restructured to provide a cleaner separation between the
frontend and the backend. As a first step towards this goal, Hawk now
uses its own small API proxy daemon as a web server, which is
maintained as a separate project:

* [API Server Repository](https://github.com/krig/hawk-apiserver)


## A Note on SSL Certificates

The Hawk init script will automatically generate a self-signed SSL
certificate, in `/etc/hawk/hawk.pem`.  If you want
to use your own certificate, replace `hawk.key` and `hawk.pem` with
your certificate. For browsers to accept this certificate, the node running Hawk will need to be accessed via the domain name specified in the certificate.
