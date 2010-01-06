package Jifty::Plugin::Timing;
use strict;
use warnings;
use base 'Jifty::Plugin';
use Time::HiRes qw//;

sub prereq_plugins { 'RequestInspector' }

our @hooks = qw/
                  before_request have_request
                  before_dispatcher_SETUP   after_dispatcher_SETUP
                  before_dispatcher_RUN
                  before_render_template    after_render_template
                  after_dispatcher_RUN
                  before_flush              after_flush
                  before_dispatcher_CLEANUP after_dispatcher_CLEANUP
                  before_cleanup
                  after_request
              /;

my @request;

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');

    for my $hook (@hooks) {
        next if $hook eq "before_request" or $hook eq "after_request";
        Jifty::Handler->add_trigger(
            $hook => sub {
                return unless @request;
                return if Jifty->web->request and Jifty->web->request->is_subrequest;

                push @request, {
                    name => $hook,
                    time => Time::HiRes::time(),
                }
            }
        );
    }
}


sub inspect_before_request {
    warn "Leftover request! " . YAML::Dump(\@request) if @request;
    @request = (
        {
            name => "before_request",
            time => Time::HiRes::time(),
        }
    );
}

sub inspect_after_request {
    my $self = shift;
    push @request,
        {
            name => "after_request",
            time => Time::HiRes::time(),
        };
    for ( 1 .. $#request ) {
        $request[$_]{diff}  = $request[$_]{time} - $request[$_-1]{time};
        $request[$_]{cumul} = $request[$_]{time} - $request[0]{time};
    }
    my $ret = [ @request ];
    @request = ();
    return $ret;
}

sub inspect_render_summary {
    my $self = shift;
    my $log = shift;

    return _("Total time, %1", sprintf("%5.4f",$log->[-1]{time} - $log->[0]{time}));
}

sub inspect_render_analysis {
    my $self = shift;
    my $log = shift;
    my $id = shift;

    Jifty::View::Declare::Helpers::render_region(
        name => 'timing',
        path => '/__jifty/admin/requests/timing',
        args => {
            id => $id,
        },
    );
}

sub inspect_render_aggregate {
    my $self = shift;
    Jifty::View::Declare::Helpers::render_region(
        name => 'timing-aggregate',
        path => '/__jifty/admin/requests/timing_aggregate',
    );
}

1;


__END__

=head1 NAME

Jifty::Plugin::Timing - Show timing of hifty internals

=head1 DESCRIPTION

This plugin will log the time various parts of the jifty framework
take to respond to a request, and generate reports.  Such reports are
available at:

    http://your.app/__jifty/admin/requests

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Timing: {}

=head1 METHODS

=head2 init

Adds the necessary hooks

=head2 inspect_before_request

Clears the query log so we don't log any unrelated previous queries.

=head2 inspect_after_request

Stash the query log.

=head2 inspect_render_summary

Display how many queries and their total time.

=head2 inspect_render_analysis

Render a template with all the detailed information.

=head2 inspect_render_aggregate

Render a template with aggragate information.

=head2 prereq_plugins

This plugin depends on L<Jifty::Plugin::RequestInspector>.

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut
