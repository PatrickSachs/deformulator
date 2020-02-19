-module(github_demo).
-export([hello_world/2]).

hello_world(Name, Age) ->
	FullGreeting = case Age of
		Age when Age >= 18 -> "Access granted, " ++ Name;
		_ -> "Access denied."
	end,
	io:format(FullGreeting).
