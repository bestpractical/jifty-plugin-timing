package Jifty::Plugin::Timing::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests/timing' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id = get('id');

    my $data = $request_inspector->get_plugin_data($id, "Jifty::Plugin::Timing");
    table {
        row {
            th { $_ } for ("Stage", "Cumulative time", "Difference");
        };
        for (@{$data}) {
            row {
                cell { $_->{name} }
                cell { sprintf("%5.4f",$_->{cumul} || 0) }
                cell { sprintf("%5.4f",$_->{diff}  || 0) }
            }
        }
    }
};

template '/__jifty/admin/requests/timing_aggregate' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');

    my @data = $request_inspector->get_all_plugin_data("Jifty::Plugin::Timing");
    unless (@data) {
        outs "No data yet.";
        return;
    }

    my %avg;
    for my $req (@data) {
        for (@{$req}) {
            $avg{$_->{name}}{diff}  += $_->{diff} || 0;
            $avg{$_->{name}}{cumul} += $_->{cumul} || 0;
        }
    }

    p { "Over ".(scalar @data)." requests:" }
    table {
        row {
            th { $_ } for ("Stage", "Cumulative time", "Difference");
        };
        for (@Jifty::Plugin::Timing::hooks) {
            row {
                cell { $_ }
                cell { sprintf("%5.4f",$avg{$_}{cumul}/@data) }
                cell { sprintf("%5.4f",$avg{$_}{diff}/@data) }
            }
        }
    }
};

1;

__END__

=head1 NAME

Jifty::Plugin::Timing::View - View for Timing

=cut

