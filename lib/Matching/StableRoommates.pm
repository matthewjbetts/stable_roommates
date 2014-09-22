=head1 NAME

 Matching::StableRoommates

=head1 DESCRIPTION

 http://en.wikipedia.org/wiki/Stable_roommates_problem

=head1 EXAMPLE USAGE

=head1 AUTHOR - Matthew Betts

 mailto:bettsmatthew@googlemail.com

=cut

package Matching::StableRoommates;

use strict;
use warnings;
use Moose;
use vars qw($VERSION);

$VERSION = "0.01a";

=head1 ACCESSORS

=cut

=head2 n_pairs

 usage   :
 function: the desired number of pairings per participant
 args    :
 returns :

=cut
has 'n_pairs' => (is => 'ro', isa => 'Int', required => 1, default => 1);

=head2 preferences

 usage   : $self->preferences();         # get the preference lists for all participants as a hash ref
           $self->preferences($x);       # get the preferences for a particular participant as a list ref,
           $self->preferences($x, $idx); # get the participant at a particular position in a particular participant's as preference list,
 function:
 args    : a participant identifier (optional)
 returns : a hash ref, a list or a scalar

=cut

has 'preferences' => (is => 'ro', isa => 'HashRef[Any]', required => 1);

around preferences => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $idx  = shift;

    if(defined($id)) {
        defined($self->preferences->{$id}) or ($self->preferences->{$id} = []);
        if(defined($idx)) {
            return $self->preferences->{$id}->[$idx];
        }
        else {
            return $self->preferences->{$id};
        }
    }
    else {
        return $self->$orig;
    }
};

=head2 ignore

 usage   : $self->ignore($x, $y); # find out if $y is ignored in $x's preference list
           $self->ignore($x, $y, 1); # mark $y as to be ignored in $x's preference list
 function:
 args    :
 returns :

=cut

has 'ignore' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}});

around ignore => sub {
    my $orig  = shift;
    my $self  = shift;
    my $x     = shift;
    my $y     = shift;
    my $ignore = shift;

    if(defined($x)) {
        if(defined($y)) {
            defined($ignore) and ($self->ignore->{$x}->{$y} = $ignore);
            defined($self->ignore->{$x}->{$y}) or ($self->ignore->{$x}->{$y} = 0);
            return $self->ignore->{$x}->{$y};
        }
        else {
            return $self->ignore->{$x};
        }
    }
    else {
        return $self->$orig;
    }
};

=head2 preference_idx

 usage   : $self->preference_idx($x, $y); # get position of $y in $x's preference list
           $self->preference_idx($x, $y, $idx); # set position of $y in $x's preference list
 function:
 args    :
 returns :

=cut

has 'preference_idx' => (is => 'ro', isa => 'HashRef[Any]', required => 1);

around preference_idx => sub {
    my $orig = shift;
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    my $idx  = shift;

    if(defined($x)) {
        if(defined($y)) {
            defined($idx) and ($self->preference_idx->{$x}->{$y} = $idx);
            return $self->preference_idx->{$x}->{$y};
        }
        else {
            return $self->preference_idx->{$x};
        }
    }
    else {
        return $self->$orig;
    }
};

=head2 current_preference_idx

 usage   : $self->current_preference_idx($x);       # get the current position in the preference list of a particular participant
           $self->current_preference_idx($x, $idx); # set the current position in the preference list of a particular participant
 function: get/set the current position in the preference list of a particular participant
 args    :
 returns :

=cut

has 'current_preference_idx' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around current_preference_idx => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $idx  = shift;

    if(defined($id)) {
        defined($self->current_preference_idx->{$id}) or ($self->current_preference_idx->{$id} = -1);
        defined($idx) and ($self->current_preference_idx->{$id} = $idx);
        return $self->current_preference_idx->{$id};
    }
    else {
        return $self->$orig;
    }
};

=head2 participants

 usage   :
 function: built from the preference lists when the object is constructed
 args    :
 returns :

=cut

has 'participants' => (is => 'ro', isa => 'ArrayRef[Any]', required => 1);

=head2 proposals_to

 usage   : $self->proposals_to(); # get all accepted proposals as a hash ref
           $self->proposals_to($x); # get id of participant whose proposal to $x was accepted by $x
           $self->proposals_to($x, $y); # set proposal accepted by $x to come from $y
 function:
 args    : a participant identifier (optional)
 returns : a hash ref or a scalar

=cut

has 'proposals_to' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around proposals_to => sub {
    my $orig = shift;
    my $self = shift;
    my $x    = shift;
    my $y    = shift;

    if(defined($x)) {
        if(defined($y)) {
            $self->proposals_to->{$x} = $y;
            $self->proposals_from->{$y} = $x;
        }
        return $self->proposals_to->{$x};
    }
    else {
        return $self->$orig;
    }
};

=head2 proposals_from

 usage   : $self->proposals_from($y); # get identifier of participant that accepted a proposal from $y
 function:
 args    : a participant identifier
 returns : a scalar

=cut

has 'proposals_from' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around proposals_from => sub {
    my $orig = shift;
    my $self = shift;
    my $y    = shift;

    if(defined($y)) {
        return $self->proposals_from->{$y};
    }
    else {
        return $self->$orig;
    }
};

=head2 ranking

 usage   : $self->ranking;                    # get ranking matrix hash
           $self->ranking($x);              # get ranking matrix hash for $x
           $self->ranking($x, $y);        # get rank of $y in $x's preference list
           $self->ranking($x, $y, $rank); # set rank of $y in $x's preference list
 function:
 args    :
 returns :

=cut

has 'ranking' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around ranking => sub {
    my $orig = shift;
    my $self = shift;
    my $x  = shift;
    my $y  = shift;
    my $rank = shift;

    if(defined($x)){
        if(defined($y)) {
            if(defined($rank)) {
                $self->ranking->{$x}->{$y} = $rank;
                return $rank;
            }
            else {
                # if $y is in $x's preference list, return its rank
                # if not, return the lowest rank possible, i.e. the number of participants
                $rank = defined($self->ranking->{$x}->{$y}) ? $self->ranking->{$x}->{$y} : $self->n_participants;
                return $rank;
            }
        }
        else {
            return $self->ranking->{$x};
        }
    }
    else {
        return $self->$orig;
    }
};

=head2 debug

 usage   :
 function:
 args    :
 returns :

=cut

has 'debug' => (is => 'ro', isa => 'Int', default => 0);

=head1 METHODS

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my @args;
    my $participants;
    my $x;
    my $y;
    my $i;
    my $j;
    my $k;
    my $key;
    my $value;
    my $preferences;
    my $preference_idx;
    my $n_pairs_max;
    my $n_pairs;

    @args = ();

    $participants = undef;
    for($i = 0, $j = 1; $j < @_; $i += 2, $j += 2) {
        ($key, $value) = @_[$i..$j];

        # get participants from preferences
        if($key eq 'preferences') {
            (ref($value) ne 'HASH') and Carp::croak('preferences should be given as a hash');
            $preferences = $value;
            $preference_idx = {};
            $participants = {};
            foreach $x (keys %{$preferences}) {
                $participants->{$x}++;
                $k = 0;
                foreach $y (@{$preferences->{$x}}) {
                    $participants->{$y}++;
                    $preference_idx->{$x}->{$y} = $k;
                    ++$k;
                }
            }
            $participants = [sort keys %{$participants}];
            push @args, 'participants', $participants, 'preference_idx', $preference_idx;

            # max number of pairs per participant = number of participants - 1
            $n_pairs_max = scalar @{$participants} - 1;
        }
        elsif($key eq 'n_pairs') {
            $n_pairs = $value;
            next;
        }
        elsif($key eq 'participants') {
            next;
        }

        push @args, $key, $value;
    }
    (($n_pairs < 1) or ($n_pairs > $n_pairs_max)) and ($n_pairs = $n_pairs_max);
    push @args, 'n_pairs', $n_pairs;

    return $class->$orig(@args);
};

sub BUILD {
    my($self) = @_;

    my $x;
    my $y;
    my $i;
    my $j;
    my $seen;

    ($self->n_pairs <= 0) and Carp::croak('n_pairs <= 0');
    (keys(%{$self->preferences}) == 0) and Carp::croak('empty preference list');

    # build ranking matrix
    foreach $x (@{$self->participants}) {
        $i = 0;
        foreach $y (@{$self->preferences($x)}) {
            $self->ranking->{$x}->{$y} = $i;
            $seen->{$y}++;
            ++$i;
        }
    }
}

=head2 current_preference_idx_incr

 usage   :
 function:
 args    :
 returns :

=cut

sub current_preference_idx_incr {
    my($self, $id) = @_;

    my $idx;

    $idx = $self->current_preference_idx($id, $self->current_preference_idx($id) + 1);

    return $idx;
}

=head2 current_preference_idx_reset

 usage   :
 function:
 args    :
 returns :

=cut

sub current_preference_idx_reset {
    my($self, $id) = @_;

    my @ids;

    @ids = defined($id) ? ($id) : @{$self->participants};
    foreach $id (@ids) {
        $self->current_preference_idx($id, -1);
    }
}

=head2 next_preference

 usage   :
 function:
 args    :
 returns :

=cut

sub next_preference {
    my($self, $x) = @_;

    my $idx;
    my $y;

    $idx = $self->current_preference_idx_incr($x);
    $y = $self->preferences($x, $idx);

    return $y;
}


=head2 n_participants

 usage   : $self->n_participants;
 function: number of participants
 args    :
 returns :

=cut

sub n_participants {
    my($self) = @_;

    my @parts;

    @parts = @{$self->participants};
    return scalar @parts;
}

=head2 n_preferences

 usage   : $self->n_preferences($id);
 function: number of preferences by the given participant
 args    :
 returns :

=cut

sub n_preferences {
    my($self, $id) = @_;

    my @prefs;

    @prefs = @{$self->preferences($id)};
    return scalar @prefs;
}

=head2 remove_proposal

 usage   : $self->remove_proposal($x);
 function: remove the proposal currently held by $x
 args    :
 returns :

=cut

sub remove_proposal {
    my($self, $x) = @_;

    my $y;

    $y = $self->proposals_to->{$x};
    $self->proposals_to->{$x} = undef;
    delete $self->proposals_to->{$x};

    if(defined($y)) {
        $self->proposals_from->{$y} = undef;
        delete $self->proposals_from->{$y};
    }
}

=head2 output

 usage   : $self->output($fh);
 function: print the preferences as a tsv
 args    : a file handle glob (defaults to \*STDOUT)
 returns : 1 on success

=cut

sub output_tsv {
    my($self, $fh) = @_;

    my $id;

    defined($fh) or ($fh = \*STDOUT);
    foreach $id (@{$self->participants}) {
        print $fh join("\t", $id, @{$self->preferences($id)}), "\n";
    }

    return 1;
}

=head2 propose

 usage   : $self->propose($x, $y, $queue);
 function: $x receives a proposal from $y
           $x accepts the proposal if it hasn't yet accepted a proposal or this proposal is better.
 args    : id of proposee, id of proposer, ref to array of participants waiting to propose
 returns :

=cut

sub propose {
    my($self, $x, $y, $queue) = @_;

    my $accepted;
    my $rank0;
    my $rank1;
    my $z;
    my $idx;
    my $a;

    $self->debug and print("$y -> $x");

    $accepted = 0;
    if(defined($z = $self->proposals_to($x))) {
        # is the new proposal preferred over the existing ones?
        $rank0 = $self->ranking($x, $y);
        $rank1 = $self->ranking($x, $z);

        #$self->debug and print("$y is at rank $rank0, $z is at rank $rank1\n");

        if($rank1 > $rank0) {
            # remove $z from $x's accepted proposals
            $self->remove_proposal($x);
            $self->debug and print("; rem $x x $z ($z < $y)");

            # $z then has to propose to someone else, so put it back on to the queue
            unshift @{$queue}, $z;

            # add $y to $x's accepted proposals
            $self->proposals_to($x, $y);
            ++$accepted;
        }
        else {
            # $x rejects $y's proposal
            $self->debug and print("; ign $x x $y ($y < $z)");

            # $y then has to propose to someone else, so put it back on the queue
            unshift @{$queue}, $y;
        }
    }
    else {
        # accept the proposal
        $self->proposals_to($x, $y);
        ++$accepted;
    }
    $self->debug and print("\n");

    return $accepted;
}

=head2 stable

 usage   : $self->stable();
 function: checks if a stable solution is possible (to be run after $self->phase1())
 args    :
 returns : 1 if a stable solution is possible, 0 if not

=cut

sub stable {
    my($self) = @_;

    my $p;

    foreach $p (@{$self->participants}) {
    }

    return 0;
}


=head2 phase1

 usage   : $self->phase1();
 function: phase 1 of the Irving algorithm
 args    :
 returns : 1 on success

=cut

sub phase1 {
    my($self) = @_;

    my $queue;
    my $y;
    my $x;
    my $n_accepted;
    my $prefix;
    my $idx;
    my $z;
    my $rank0;
    my $rank1;

    if($self->debug) {
        print "\n###### phase1 ######\n";

        print "\npreferences:\n";
        foreach $y (@{$self->participants}) {
            print join("\t", "$y:", @{$self->preferences($y)}), "\n";
        }
    }

    $self->current_preference_idx_reset();
    $queue = [(@{$self->participants}) x $self->n_pairs];
    while($y = shift @{$queue}) {
        $n_accepted = 0;
        #while(defined($x = $self->next_preference($y))) {
        #    $self->propose($y, $x, $queue) and ++$n_accepted;
        #    ($n_accepted == $self->n_pairs) and last;
        #}

        if(defined($x = $self->next_preference($y))) {
            $self->propose($x, $y, $queue) and ++$n_accepted;
        }
    }
    $self->current_preference_idx_reset();

    if($self->debug) {
        print "\nproposals:\n";
        foreach $y (@{$self->participants}) {
            print join(' ', $y, '<-', $self->proposals_to($y)), "\n";
        }
    }

    # reduce the preference lists
    foreach $y (@{$self->participants}) {
        $x = $self->proposals_to($y);

        # ignore all those in $y's preference list to whom $y prefers $x
        # i.e. ignore everything after $x from $y's preference list
        # i.e. $x is last on $y's list
        for($idx = $self->preference_idx($y, $x) + 1; $idx < @{$self->preferences($y)}; ++$idx) {
            $self->ignore($y, $self->preferences($y, $idx), 1);
        }

        # ignore all those in $x's preference list that are before $y
        # i.e. $y is first on $x's list
        for($idx = 0; $idx < $self->preference_idx($x, $y); $idx++) {
            $self->ignore($x, $self->preferences($x, $idx), 2);
        }

        # ignore any remaining preferences which have a better proposal already
        foreach $x (@{$self->preferences($y)}) {
            ($self->ignore($y, $x) == 0) or next;
            $rank0 = $self->ranking($x, $y);
            $z = $self->proposals_to($x);
            $rank1 = $self->ranking($x, $z);
            if($rank1 < $rank0) {
                $self->ignore($y, $x, 3);
            }
        }
    }

    if($self->debug) {
        print "\nreduced preferences:\n";
        foreach $x (@{$self->participants}) {
            print "$x:";
            foreach $y (@{$self->preferences($x)}) {
                print "\t", $y, ($self->ignore($x, $y) == 0) ? '' : join('', '(', $self->ignore($x, $y), ')');
            }
            print "\n";
        }
    }

    return 1;
}

=head2 phase2

 usage   : $self->phase1();
 function: phase 2 of the Irving algorithm
 args    :
 returns : 1 on success, 0 on failure

=cut

sub phase2 {
    my($self) = @_;

    my $p;
    my $q;
    my $info;
    my $ps;
    my $qs;
    my $cycle;
    my $ps_seen;
    my $a;
    my $b;
    my $b2;
    my $idx;
    my $cycle_n;
    my $i;

    $self->debug() and print("\n###### phase2 ######\n");

    $cycle_n = 0;
    while(1) {
        # get the first, second, last and number of preferences on each participant's reduced list
        $info = {};
        foreach $p (@{$self->participants}) {
            $info->{$p} = {
                           first  => undef,
                           second => undef,
                           last   => undef,
                           n      => 0,
                          };
            foreach $q (@{$self->preferences($p)}) {
                ($self->ignore($p, $q) == 0) or next;

                if(defined($info->{$p}->{first})) {
                    defined($info->{$p}->{second}) or ($info->{$p}->{second} = $q);
                }
                else {
                    $info->{$p}->{first} = $q;
                }
                $info->{$p}->{last} = $q;
                $info->{$p}->{n}++;
            }
        }

        # find a participant with at least two members on its reduced list
        $ps = [];
        foreach $p (@{$self->participants}) {
            if($info->{$p}->{n} > 1) {
                push @{$ps}, $p;
                last;
            }
            elsif($info->{$p}->{n} == 0) {
                return 0;
            }
        }
        (@{$ps} > 0) or last;
        ++$cycle_n;
        $self->debug() and print("CYCLE $cycle_n: p1 = $ps->[0]\n");

        # find a rotation
        $qs = [];
        $cycle = undef;
        $i = 0;
        $ps_seen = {};
        while($i < $self->n_participants) {
            ++$i;
            $p = $ps->[$#{$ps}];
            $ps_seen->{$p}++;
            $q = $info->{$p}->{second};
            $self->debug and print("ROT p = $p, q = $q\n");
            $p = $info->{$q}->{last};
            if(defined($ps_seen->{$p})) {
                $self->debug() and print "SEEN: $p\n";
                $cycle = $ps;
                last;
            }
            push @{$ps}, $p;
        }
        if(!defined($cycle)) {
            warn "Error: Matching::StableRoommates: no rotation found.";
            return 0;
        }
        $cycle = [@{$cycle}[1..$#{$cycle}]];

        $self->debug and print("cycle = @{$cycle}\n");

        # eliminate the rotation

        # reject proposals from members of the cycle
        foreach $a (@{$cycle}) {
            # find $b that has accepted a proposal from $a
            $b = $self->proposals_from($a);

            # $b rejects proposal from $a
            $self->remove_proposal($b);
            $self->debug() and print("REMOVE PROPOSAL $b <- $a\n");

            # ignore $a in $b's preference list
            $self->ignore($b, $a, 4);

            # must also ignore $b in $a's preference list
            $self->ignore($a, $b, 5);
            $self->debug() and print("IGNORE $b in ${a}'s preference list (therefore IGNORE $a in ${b}'s preference list)\n");
        }

        # the members of the cycle must now propose to the next person on their reduced preference list
        foreach $a (@{$cycle}) {
            # $a must now propose to the next person on its reduced preference list
            foreach $b2 (@{$self->preferences($a)}) {
                $self->debug() and print("PROPOSE $a -> $b2, ignored = ", $self->ignore($a, $b2), "\n");

                ($self->ignore($a, $b2) == 0) or next;
                $self->proposals_to($b2, $a);
                $self->debug() and print("ACCEPT $b2 <- $a\n");

                # ignore all successors of $a in $b2's reduced preference list,
                # and ignore $b2 in their lists
                for($idx = $self->preference_idx($b2, $a) + 1; $idx < @{$self->preferences($b2)}; ++$idx) {
                    ($self->ignore($b2, $self->preferences($b2, $idx)) == 0) and $self->ignore($b2, $self->preferences($b2, $idx), 6);
                    ($self->ignore($self->preferences($b2, $idx), $b2) == 0) and $self->ignore($self->preferences($b2, $idx), $b2, 7);
                }

                last;
            }
        }

        if($self->debug) {
            print "\ncycle $cycle_n, reduced preferences:\n";
            foreach $p (@{$self->participants}) {
                print "$p:";
                foreach $q (@{$self->preferences($p)}) {
                    print "\t", $q, ($self->ignore($p, $q) == 0) ? '' : join('', '(', $self->ignore($p, $q), ')');
                }
                print "\n";
            }

            print "\nproposals:\n";
            foreach $p (@{$self->participants}) {
                print join(' ', $p, '<-', $self->proposals_to($p)), "\n";
            }
        }

        ($cycle_n > 3) and last;
    }

    return 1;
}



1;
