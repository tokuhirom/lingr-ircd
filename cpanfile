# requires 'Exporter'                      => '0';
requires 'parent'                        => '0';
requires 'AnyEvent::IRC::Server';
requires 'AnyEvent';
requires 'AnyEvent::Lingr';
requires 'Mouse' => 1.05;
# requires 'Plack'                         => '0.9949';

on 'configure' => sub {
    requires 'Module::Build' => '0.40';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
    requires 'Module::Build::Pluggable::GithubMeta';
};

on 'test' => sub {
    requires 'Test::More' => '0.98';
    requires 'Test::Requires' => 0;
};

on 'devel' => sub {
    # Dependencies for developers
};
