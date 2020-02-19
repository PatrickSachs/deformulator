{:beam_file, :github_demo,
 [{:hello_world, 2, 2}, {:module_info, 0, 6}, {:module_info, 1, 8}],
 [vsn: [25922635909147774279658602819796061227]],
 [
   version: '7.5',
   options: [],
   source: '/home/patrick/Development/deformulator/priv/github_demo.erl'
 ],
 [
   {:function, :hello_world, 2, 2,
    [
      {:label, 1},
      {:line, 1},
      {:func_info, {:atom, :github_demo}, {:atom, :hello_world}, 2},
      {:label, 2},
      {:allocate, 0, 2},
      {:test, :is_ge, {:f, 3}, [x: 1, integer: 18]},
      {:move, {:x, 0}, {:x, 1}},
      {:move, {:literal, 'Access granted, '}, {:x, 0}},
      {:line, 2},
      {:call_ext, 2, {:extfunc, :erlang, :++, 2}},
      {:jump, {:f, 4}},
      {:label, 3},
      {:move, {:literal, 'Access denied.'}, {:x, 0}},
      {:label, 4},
      {:line, 3},
      {:call_ext_last, 1, {:extfunc, :io, :format, 1}, 0}
    ]},
   {:function, :module_info, 0, 6,
    [
      {:line, 0},
      {:label, 5},
      {:func_info, {:atom, :github_demo}, {:atom, :module_info}, 0},
      {:label, 6},
      {:move, {:atom, :github_demo}, {:x, 0}},
      {:line, 0},
      {:call_ext_only, 1, {:extfunc, :erlang, :get_module_info, 1}}
    ]},
   {:function, :module_info, 1, 8,
    [
      {:line, 0},
      {:label, 7},
      {:func_info, {:atom, :github_demo}, {:atom, :module_info}, 1},
      {:label, 8},
      {:move, {:x, 0}, {:x, 1}},
      {:move, {:atom, :github_demo}, {:x, 0}},
      {:line, 0},
      {:call_ext_only, 2, {:extfunc, :erlang, :get_module_info, 2}}
    ]}
 ]}
