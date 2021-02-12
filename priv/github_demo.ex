%Deformulator.Expressions.Case{
  branches: [
    %Deformulator.Expressions.Case.Branch{
      expressions: [
        %Deformulator.Expressions.Bind{
          source: %Deformulator.Expressions.Binding{var: "param0_x0"},
          target: %Deformulator.Expressions.Binding{var: "var2_x1"}
        },
        %Deformulator.Expressions.Bind{
          source: %Deformulator.Expressions.Literal{
            value: 'Access granted, '
          },
          target: %Deformulator.Expressions.Binding{var: "var3_x0"}
        },
        %Deformulator.Expressions.Bind{
          source: %Deformulator.Expressions.CallMfa{
            arguments: [
              %Deformulator.Expressions.Binding{var: "var3_x0"},
              %Deformulator.Expressions.Binding{var: "var2_x1"}
            ],
            arity: 2,
            function: :++,
            module: :erlang
          },
          target: %Deformulator.Expressions.Binding{var: "var4_x0"}
        },
        %Deformulator.Expressions.CallMfa{
          arguments: [%Deformulator.Expressions.Binding{var: "var4_x0"}],
          arity: 1,
          function: :format,
          module: :io
        }
      ],
      guard: %Deformulator.Expressions.Literal{value: true}
    },
    %Deformulator.Expressions.Case.Branch{
      expressions: [
        %Deformulator.Expressions.Bind{
          source: %Deformulator.Expressions.Literal{
            value: 'Access denied.'
          },
          target: %Deformulator.Expressions.Binding{var: "var5_x0"}
        },
        %Deformulator.Expressions.CallMfa{
          arguments: [%Deformulator.Expressions.Binding{var: "var5_x0"}],
          arity: 1,
          function: :format,
          module: :io
        }
      ],
      guard: %Deformulator.Expressions.Literal{value: false}
    }
  ],
  expression: %Deformulator.Expressions.CallMfa{
    arguments: [
      %Deformulator.Expressions.Binding{var: "param1_x1"},
      %Deformulator.Expressions.Literal{value: 18}
    ],
    arity: 2,
    function: :is_ge,
    module: :erlang
  }
}
]
