# imports route/post/request-body/content
use Cro::HTTP::Router:ver<0.8.13+>:auth<zef:cro>;

use Cro::HTTP::Server:ver<0.8.13+>:auth<zef:cro>;

# imports from-json/to-json
use JSON::Collector:ver<0.0.3+>:auth<zef:lizmat>;

role JSON::Webhook {
    has Str()  $!host;
    has UInt() $!port;
    has        $!application;
    has        $!server;   # the Cro::HTTP::Server if .serve called
    has        $!awaiter;  # promise to break react/whenever on .stop

    submethod TWEAK(:$host, :$port, :$application --> Nil) {
        $!host        = $host        || self.WHAT.host;
        $!port        = $port        || self.WHAT.port;
        $!application = $application || self.WHAT.application(|%_);
    }

    multi method application(JSON::Webhook:U:
      :$collector is copy,
      :&processor is copy,
    ) {
        $collector = self.collector(|%_) unless $collector;
        &processor = self.processor(|%_) unless &processor;

        route {
            post -> {
                request-body -> \data {
                    $collector.store(processor(data, request));
                    content 'text/plain', "OK";
                }
            }
        }
    }
    multi method application(JSON::Webhook:D:) { $!application }

    multi method sink(JSON::Webhook:D:) { self.serve }

    method serve() {
        $!server := Cro::HTTP::Server.new(:$!host, :$!port, :$!application);
        $!server.start;
        $!awaiter := Promise.new;
        react {
            whenever $!awaiter      { done                }
            whenever signal(SIGINT) { $!server.stop; exit }
        }
    }

    method stop() { $!server.stop; $!awaiter.keep }

#- overridable methods ---------------------------------------------------------
    method host() {
        self
          ?? $!host
          !! $*WEBHOOK-HOST // %*ENV<WEBHOOK_HOST> // "localhost"
    }
    method port() {
        self
          ?? $!port
          !! $*WEBHOOK-PORT // %*ENV<WEBHOOK_PORT> // 9999
    }
    method collector() { JSON::Collector.new(|%_)   }
    method processor() { -> \data, \request { data } }
}

# vim: expandtab shiftwidth=4
