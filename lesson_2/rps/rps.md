# Rock, Paper, Scissors

## Rubocop

Rubocop complains that the `play` method is too long,
but I thought it's ok because `play` is basically the game engine,
and it's a bunch of clear method calls, no complex logic.

## Classes and Modules

My approach with classes and modules is: if a class gets too crowded,
or there are too many methods with similar names,
I'll refactor into a class or module.

`rock`, `paper`, `scissors` etc. didn't seem to have any behavior to warrent a new class,
except for perhaps the initials `r` for `rock`, and the winning hands (what beats what),
but I still thought they fit better in the Move class as constants.

I thought `@score` was small and not referenced too much to warrent a seperate class.
On the other hand the RPSGame class got really crowded with methods
and most of those methods were just displaying things, so I refactored it to a module.

## Moves

When I added lizard and spock, rubocop complained that the '>' method was to complex,
so I changed the approach to what i've used in the previous rps game, putting the rules in a hash.
This also allowed me to delete five methods rock?, paper? etc.

## History

I started off with `player_history` as an instance variable for each player,
and displaying it at the end of each game. Later when I added AI to `Computer#choose`,
I needed `computer` to have access to `human.player_history`, so I added a class `History`,
I still left `player_history` to display at the end of each game.

The `History` class keeps track of moves and winner in all games (`play_again?`),
while `player_history` only keeps track of moves from the current game.

## Computer moves

The computer assumes that the human won't choose a move that he loses with.

If the human lost the last round, the human's last move will be the `lost_move`,
If not then we find the move that he lost with the most times,
and that will be the `lost_move`.

Once we have a `lost_move`, the computer will not choose a move that beats `lost_move`
to increase the probability of the computer winning.

To keep it simple `lost_move` will only be one move,
even if the human lost with more than one move 5 times with no move loosing more than 5 times.
