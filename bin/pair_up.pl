#!/usr/bin/perl -w

use strict;
use Matching::StableRoommates;

my $n_rounds;
my $n_rounds_max;
my $preferences;
my $preferences2;
my $participants;
my @F;
my $sr;
my $n_participants;
my $p;
my $round;
my $i;
my $j;
my $pairs_all;
my $pairs;
my $x;
my $y;

defined($n_rounds = shift @ARGV) or usage();

sub usage {
    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    die "Usage: $prog n_rounds < preferences\n";
}

$preferences = {};
$participants = {};
while(<STDIN>) {
    (/^#/ or /\A\s*\Z/) and next;
    @F = split;
    foreach $p (@F) {
        $participants->{$p}++;
    }
    $preferences->{$F[0]} = [@F[1..$#F]];
}
$participants = [sort keys %{$participants}];
$n_participants = scalar @{$participants};
$n_rounds_max = $n_participants - 1;

print <<END;

n_participants: $n_participants
n_rounds      : $n_rounds
n_rounds_max  : $n_rounds_max
END

($n_participants % 2) and die 'Error: even number of participants required.';

if($n_rounds >= $n_rounds_max) {
    print "\nall with all is possible\n\n";
    # if all by all is possible with the desired number of rounds, list the pairings in each round
}
else {
    $pairs = {};
    $pairs_all = {};
    for($round = 1; $round <= $n_rounds; $round++) {
        print "\n## round $round\n\n";

        # copy preferences, removing any pairs from previous rounds
        $preferences2 = {};
        foreach $x (keys %{$preferences}) {
            $preferences2->{$x} = [];
            foreach $y (@{$preferences->{$x}}) {
                defined($pairs_all->{$x}->{$y}) or push(@{$preferences2->{$x}}, $y);
            }
        }

        $sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => $preferences2);};
        defined($sr) or die 'could not construct Matching::StableRoommates object';

        if($sr->phase1) {
            if($sr->phase2) {
                #$sr->output();
                $pairs = $sr->pairs();
                foreach $x (sort keys %{$pairs}) {
                    foreach $y (sort keys %{$pairs->{$x}}) {
                        $pairs_all->{$x}->{$y}++;
                        print "$x\t$y\n";
                    }
                }
            }
            else {
                print "failed phase2\n";
            }
        }
        else {
            print "failed phase1\n";
        }
    }
}

