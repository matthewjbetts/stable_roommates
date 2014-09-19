use strict;
use Test::More tests => 22;

BEGIN {
    use_ok('Matching::StableRoommates');
}

my $sr;
my $preferences;
my $n_pairs;
my @wrong;
my $n_wrong;
my $id;

$sr = eval {Matching::StableRoommates->new(n_pairs => 0, preferences => {});};
ok(!$sr, "don't construct StableRoommates object with n_pairs = 0");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {});};
ok(!$sr, "don't construct StableRoommates object with empty preferences");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => [1, 2, 3]);};
ok(!$sr, "don't construct StableRoommates object with preferences given as a list");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {1 => [2, 3]});};
ok($sr, "construct StableRoommates object with integer ids");
ok(($sr->n_preferences(2) == 0), "no preferences for participant 2");
ok(($sr->n_proposals(1) == 0), "no accepted proposals for participant 1");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {'fred' => ['wilma', 'barney']});};
ok($sr, "construct StableRoommates object with string ids");

$preferences = {
                1 => [3, 4, 2, 6, 5],
                2 => [6, 5, 4, 1, 3],
                3 => [2, 4, 5, 1, 6],
                4 => [5, 2, 3, 6, 1],
                5 => [3, 1, 2, 4, 6],
                6 => [5, 1, 3, 4, 2],
               };

$n_pairs = 1;
$sr = eval {
    Matching::StableRoommates->new(n_pairs => $n_pairs, preferences => $preferences, debug => 1);
};
ok($sr, "construct StableRoommates object for example 1");
ok(($sr->n_preferences(1) == 5), "five preferences for participant 1");
ok(($sr->n_proposals(1) == 0), "no accepted proposals for participant 1");
ok(($sr->ranking(1, 3) == 0), "participant 3 is at rank 0 in participant 1's preference list");
ok(($sr->ranking(4, 6) == 3), "participant 6 is at rank 3 in participant 4's preference list");

for($n_pairs = 1; $n_pairs < 10; $n_pairs++) {
    $sr = eval {
        Matching::StableRoommates->new(n_pairs => $n_pairs, preferences => $preferences);
    };
    $sr->phase1();
    @wrong = ();
    foreach $id (@{$sr->participants}) {
        ($sr->n_proposals($id) != $sr->n_pairs) and push(@wrong, $id);
    }
    $n_wrong = scalar @wrong;
    ok((@wrong == 0), sprintf("wrong number of proposals for %d participant%s%s", $n_wrong, ($n_wrong == 1) ? '' : 's', join(' ', @wrong), ($n_wrong == 0) ? ": @wrong" : ''));
}

# FIXME - if the n_pairs >= n_pairs_max, then everyone can be paired with everyone else
# FIXME - need to make sure that at each date round, all pairs are stable
