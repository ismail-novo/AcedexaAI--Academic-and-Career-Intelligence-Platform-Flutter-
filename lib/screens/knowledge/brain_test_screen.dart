import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';

class BrainTestScreen extends StatefulWidget {
  const BrainTestScreen({super.key});
  @override
  State<BrainTestScreen> createState() => _BrainTestScreenState();
}

class _BrainTestScreenState extends State<BrainTestScreen> {
  final _intel = IntelligenceService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _openGame(Widget game) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => game));
    await _intel.load(uid: AuthService().currentUser?.uid);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brain Test',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Play games to train problem-solving. Scores update Skills board (Problem Solving, Logic, Memory, Strategy).',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ..._intel.brainSkills.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value.toStringAsFixed(0)}%'),
                subtitle: LinearProgressIndicator(value: e.value / 100),
              )),
          const Divider(),
          _tile('Tic Tac Toe', Icons.grid_3x3, () => _openGame(const TicTacToeGame())),
          _tile('Sudoku (4×4)', Icons.grid_on, () => _openGame(const SudokuGame())),
          _tile('Tower of Hanoi', Icons.stacked_bar_chart, () => _openGame(const HanoiGame())),
          _tile('Chess puzzles (mini)', Icons.sports_esports, () => _openGame(const ChessPuzzleGame())),
        ],
      ),
    );
  }

  Widget _tile(String t, IconData i, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(i, color: const Color(0xFF6C63FF)),
        title: Text(t),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});
  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  final board = List<String?>.filled(9, null);
  bool xTurn = true;
  String? winner;

  void _tap(int i) {
    if (board[i] != null || winner != null) return;
    setState(() {
      board[i] = xTurn ? 'X' : 'O';
      xTurn = !xTurn;
      winner = _check();
    });
    if (winner == 'X') {
      IntelligenceService().addBrainScore('Problem Solving', 5);
      IntelligenceService().addBrainScore('Strategy', 4);
    }
  }

  String? _check() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final l in lines) {
      if (board[l[0]] != null &&
          board[l[0]] == board[l[1]] &&
          board[l[1]] == board[l[2]]) {
        return board[l[0]];
      }
    }
    if (board.every((e) => e != null)) return 'Draw';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic Tac Toe')),
      body: Column(
        children: [
          Text(winner == null
              ? (xTurn ? 'Your turn (X)' : 'O turn')
              : winner == 'Draw'
                  ? 'Draw'
                  : '$winner wins!'),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: 9,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _tap(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(board[i] ?? '',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              for (var i = 0; i < 9; i++) board[i] = null;
              xTurn = true;
              winner = null;
            }),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});
  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  // 4x4 simple puzzle
  final puzzle = [
    [1, 0, 0, 4],
    [0, 0, 1, 0],
    [0, 1, 0, 0],
    [4, 0, 0, 2],
  ];
  late List<List<int>> grid;

  @override
  void initState() {
    super.initState();
    grid = puzzle.map((r) => List<int>.from(r)).toList();
  }

  bool _valid() {
    for (var i = 0; i < 4; i++) {
      final row = grid[i].where((e) => e != 0).toList();
      if (row.length != row.toSet().length) return false;
      final col = [grid[0][i], grid[1][i], grid[2][i], grid[3][i]]
          .where((e) => e != 0)
          .toList();
      if (col.length != col.toSet().length) return false;
    }
    return grid.every((r) => r.every((c) => c != 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku 4×4')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Fill 1–4. Fixed cells are bold.'),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: 16,
              itemBuilder: (_, i) {
                final r = i ~/ 4, c = i % 4;
                final fixed = puzzle[r][c] != 0;
                return GestureDetector(
                  onTap: fixed
                      ? null
                      : () {
                          setState(() {
                            grid[r][c] = (grid[r][c] % 4) + 1;
                          });
                        },
                  child: Container(
                    color: fixed ? Colors.indigo.shade50 : Colors.grey.shade100,
                    child: Center(
                      child: Text(
                        grid[r][c] == 0 ? '' : '${grid[r][c]}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              fixed ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_valid()) {
                await IntelligenceService().addBrainScore('Logic', 8);
                await IntelligenceService().addBrainScore('Memory', 4);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solved! Logic +8')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not complete / invalid')),
                );
              }
            },
            child: const Text('Check'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class HanoiGame extends StatefulWidget {
  const HanoiGame({super.key});
  @override
  State<HanoiGame> createState() => _HanoiGameState();
}

class _HanoiGameState extends State<HanoiGame> {
  final pegs = <List<int>>[
    [3, 2, 1],
    <int>[],
    <int>[],
  ];
  int? selected;
  int moves = 0;

  void _tap(int peg) {
    setState(() {
      if (selected == null) {
        if (pegs[peg].isNotEmpty) selected = peg;
      } else {
        if (selected == peg) {
          selected = null;
        } else {
          final disk = pegs[selected!].last;
          if (pegs[peg].isEmpty || pegs[peg].last > disk) {
            pegs[selected!].removeLast();
            pegs[peg].add(disk);
            moves++;
            selected = null;
            if (pegs[2].length == 3) {
              IntelligenceService().addBrainScore('Problem Solving', 10);
              IntelligenceService().addBrainScore('Strategy', 8);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Solved in $moves moves!')),
              );
            }
          } else {
            selected = null;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tower of Hanoi · moves $moves')),
      body: Row(
        children: List.generate(3, (p) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _tap(p),
              child: Container(
                margin: const EdgeInsets.all(8),
                color: selected == p
                    ? Colors.amber.shade100
                    : Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...pegs[p].reversed.map((d) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          width: 40.0 + d * 30,
                          height: 24,
                          color: Colors.indigo.shade300,
                          child: Center(child: Text('$d')),
                        )),
                    const SizedBox(height: 20),
                    Text('Peg ${p + 1}'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ChessPuzzleGame extends StatefulWidget {
  const ChessPuzzleGame({super.key});
  @override
  State<ChessPuzzleGame> createState() => _ChessPuzzleGameState();
}

class _ChessPuzzleGameState extends State<ChessPuzzleGame> {
  // Mini tactics: find the safe square (multiple choice)
  int q = 0;
  final puzzles = [
    {
      'q': 'King in check from a rook on the same rank with no blockers. Best idea?',
      'opts': ['Move king off the rank', 'Ignore check', 'Capture with king through check', 'Castle through check'],
      'a': 0,
    },
    {
      'q': 'Two attackers on an unprotected queen. Priority?',
      'opts': ['Save the queen / trade favorably', 'Push a random pawn', 'Resign immediately', 'Move a distant rook only'],
      'a': 0,
    },
    {
      'q': 'Fork: knight attacks king and queen. What happened?',
      'opts': ['Double attack tactic', 'Castling', 'En passant', 'Stalemate'],
      'a': 0,
    },
  ];
  int? sel;

  @override
  Widget build(BuildContext context) {
    final p = puzzles[q % puzzles.length];
    return Scaffold(
      appBar: AppBar(title: const Text('Chess tactics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['q'] as String,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...(p['opts'] as List).asMap().entries.map((e) {
              return RadioListTile<int>(
                value: e.key,
                groupValue: sel,
                title: Text(e.value as String),
                onChanged: (v) => setState(() => sel = v),
              );
            }),
            ElevatedButton(
              onPressed: sel == null
                  ? null
                  : () async {
                      final ok = sel == p['a'];
                      if (ok) {
                        await IntelligenceService().addBrainScore('Strategy', 6);
                        await IntelligenceService()
                            .addBrainScore('Problem Solving', 4);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Correct! Strategy up' : 'Try again')));
                      setState(() {
                        q++;
                        sel = null;
                      });
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
