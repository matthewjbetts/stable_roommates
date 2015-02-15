# Introduction

Give a group of people who might want to talk to each other, how would
you pair them up? We tried this by having initial 'speed dates', where
people talk to about five random people for about two minutes each,
and then put those five people in order of who they would most like to
talk to for longer. We then paired them up, with several rounds of
pairing, based on those preference lists using Irving's algorithm for
the stable roommates problem:

* http://en.wikipedia.org/wiki/Stable_roommates_problem
* http://www.dcs.gla.ac.uk/~pat/jchoco/roommates/papers/Comp_sdarticle.pdf

This is implemented here in Perl in a program known as
'StableRoommmates'. Each person lists all the other people present
that they would like to talk to, in order of preference. The algorithm
then attempts a 'stable matching': to pair people up such that there
is no pair where both members prefer another partner to the one they
have been paired with. Such a pairing is not always possible.

## Caveats / Expectation management

* not everyone will get to speak to their preferred people
* people can be paired with people not on their preference lists
* I haven't made much attempt yet to make StableRoommates friendly or
  easy for other people to use

## Adaptations to Irving's algorithm implemented in StableRoommmates

(I've not attempted a mathematical/computatioanl proof of any of these.)

### Incomplete preference lists
Irving's algorithm assumes that everyone has listed everyone else: if
you have X people, then everyone should have a prefence list X-1 long.
So I adapted it to allow for partial preference lists. All people not
listed by a particular person will be added on to the end of that
person's given preference list.

### Multiple rounds of pairing
Multiple rounds of pairing are possible, with pairings from previous
rounds removed from preference lists.

### Random pairings when no stable pairing is found
If no stable pairing is found in a particular round, people will be
paired randomly.

# Installation
    perl Makefile.PL
    make
    make test
    make install

# Usage

See bin/pair_up.pl
