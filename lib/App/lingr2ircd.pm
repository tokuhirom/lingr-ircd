package App::lingr2ircd;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.0.1';

use AnyEvent::Lingr;
use AnyEvent::IRC::Server;
use Encode;

use Mouse;

has ircd_host => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '127.0.0.1',
);

has ircd_port => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 6667,
);

has lingr_user => (
    is => 'rw',
    required => 1,
);

has lingr_password => (
    is => 'rw',
    required => 1,
);

has lingr_api_key => (
    is => 'rw',
    required => 0,
);

has lingr => (
    is => 'rw',
    required => 0,
);

has ircd => (
    is => 'rw',
    required => 0,
);

no Mouse;

sub run {
    my $self = shift;

    $self->ircd($self->setup_ircd());

    $self->lingr($self->setup_lingr());

    return;
}

sub setup_ircd {
    my $self = shift;

    my $ircd = AnyEvent::IRC::Server->new(
        host => $self->ircd_host,
        port => $self->ircd_port,
    );
    $ircd->reg_cb(
        daemon_privmsg => sub {
            my ($irc, $nick, $chan, $text) = @_;
            print decode_utf8("$nick, $chan, $text\n");
            if ($self->lingr) {
                my $room = $chan;
                $room =~ s!^#!!;
                $self->lingr->say($room, $text, sub {
                    print "Post okay\n";
                });
            } else {
                warn "Lingr connection is not ready yet.\n";
            }
        },
    );
    $ircd->run();

    return $ircd;
}

sub setup_lingr {
    my $self = shift;

    my $lingr = AnyEvent::Lingr->new(
        user     => $self->lingr_user,
        password => $self->lingr_password,
        api_key  => $self->lingr_api_key,
    );

    $lingr->on_error(
        sub {
            my ($msg) = @_;
            warn 'Lingr error: ', $msg;

            # reconnect after 5 seconds,
            my $t;
            $t = AnyEvent->timer(
                after => 5,
                cb    => sub {
                    $lingr->start_session;
                    undef $t;
                },
            );
        }
    );

    # room info handler
    $lingr->on_room_info(
        sub {
            my ($rooms) = @_;

            print "Joined rooms:\n";
            for my $room (@$rooms) {
                print "  $room->{id}\n";
            }
        }
    );

    # event handler
    my %topic_set;
    $lingr->on_event(
        sub {
            my ($event) = @_;

            # print message
            if ( my $msg = $event->{message} ) {
                print sprintf "[%s] %s(%s): %s\n", $msg->{room}, $msg->{nickname}, $msg->{type}, $msg->{text};

                if ($msg->{speaker_id} eq $self->lingr_user) {
                    print "It's me.\n";
                } else {
                    # $self->ircd->daemon_cmd_join("$msg->{speaker_id}", "#$msg->{room}");
                    # use Data::Dumper; warn Dumper($msg);
                    unless ($topic_set{$msg->{room}}++) {
                        $self->ircd->daemon_cmd_topic("\@$msg->{speaker_id}", '#' . $msg->{room}, "http://lingr.com/room/$msg->{room}");
                    }
                    my $meth = $msg->{type} eq 'bot' ? 'daemon_cmd_notice' : 'daemon_cmd_privmsg';
                    for my $text (split /\n/, $msg->{text}) {
                        $self->ircd->$meth("\@$msg->{speaker_id}", '#' . $msg->{room}, encode_utf8($text));
                    }
                }
            }
        }
    );

    # start lingr session
    $lingr->start_session;

    return $lingr;
}


1;
__END__

=encoding utf8

=head1 NAME

App::lingr2ircd - IRCD gateway for lingr

=head1 DESCRIPTION

App::lingr2ircd is IRCD gateway for lingr. Please look L<lingr2ircd> for more details.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
