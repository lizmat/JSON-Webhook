use Cro::HTTP::Router:ver<0.8.13+>:auth<zef:cro>;
use Cro::HTTP::Server:ver<0.8.13+>:auth<zef:cro>;
use JSON::Collector:ver<0.0.2+>:auth<zef:lizmat>;

role JSON::Webhook {
    has Str()  $!host;
    has UInt() $!port;
    has        $!application;

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
            post -> *%nameds {
                request-body -> \data {
                    $collector.store(processor(data, %nameds));
                    content 'text/plain', "OK";
                }
            }
        }
    }
    multi method application(JSON::Webhook:D:) { $!application }

    multi method sink(JSON::Webhook:D:) { self.start }

    method serve() {
        my $server := Cro::HTTP::Server.new(:$!host, :$!port, :$!application);
        $server.start;
        react whenever signal(SIGINT) { $server.stop; exit }
    }

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
    method processor() { -> \data, %nameds { data } }
}

# vim: expandtab shiftwidth=4
