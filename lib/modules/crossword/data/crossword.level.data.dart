import '../models/crossword.data.model.dart';

final CrosswordLevel level1 = CrosswordLevel(
  id: "1", // Changed to String ID
  rows: 8,
  cols: 8,
  clues: [
    Clue(
      id: "A1",
      number: 1,
      direction: Direction.across,
      clue: "Mobile app framework", // Changed from 'hint' to 'clue'
      answer: "FLUTTER",
      startRow: 0,
      startCol: 1,
    ),
    Clue(
      id: "A4",
      number: 4,
      direction: Direction.across,
      clue: "User Interface", // Changed from 'hint' to 'clue'
      answer: "UI",
      startRow: 3,
      startCol: 5,
    ),
    Clue(
      id: "A5",
      number: 5,
      direction: Direction.across,
      clue:
          "Builds for mobile, web, and desktop", // Changed from 'hint' to 'clue'
      answer: "DART",
      startRow: 4,
      startCol: 4,
    ),
    Clue(
      id: "D1",
      number: 1,
      direction: Direction.down,
      clue: "Not slow", // Changed from 'hint' to 'clue'
      answer: "FAST",
      startRow: 0,
      startCol: 1,
    ),
    Clue(
      id: "D2",
      number: 2,
      direction: Direction.down,
      clue: "A visual element", // Changed from 'hint' to 'clue'
      answer: "WIDGET",
      startRow: 1,
      startCol: 3,
    ),
    Clue(
      id: "D3",
      number: 3,
      direction: Direction.down,
      clue: "Holds app data", // Changed from 'hint' to 'clue'
      answer: "STATE",
      startRow: 1,
      startCol: 7,
    ),
  ],
);

// --- Level 1 Data (Based on image (3).png) ---
final CrosswordLevel level2 = CrosswordLevel(
  id: '2', // Changed to String ID
  rows: 12,
  cols: 12,
  clues: [
    // ACROSS
    Clue(
      id: 'A1',
      number: 1,
      direction: Direction.across,
      startRow: 0,
      startCol: 0,
      answer: 'EXTENSIVE',
      clue:
          '(adj.) covering a large area; comprehensive.', // normalized to fit grid
    ),
    Clue(
      id: 'A5',
      number: 5,
      direction: Direction.across,
      startRow: 5,
      startCol: 0,
      answer: 'PERCEPTIVE',
      clue:
          '(adj.) having or showing an ability to notice or understand things quickly and accurately', // Changed to 'clue'
    ),
    Clue(
      id: 'A6',
      number: 6,
      direction: Direction.across,
      startRow: 4, // moved off row 5 to avoid overlap with A5
      startCol: 4,
      answer: 'ENHANCE',
      clue:
          '(v.) to sharpen or improve something, especially a skill or ability.', // Changed to 'clue'
    ),
    Clue(
      id: 'A7',
      number: 7,
      direction: Direction.across,
      startRow: 6,
      startCol: 0,
      answer: 'MYOPIC',
      clue:
          '(adj.) lacking foresight or intellectual insight; shortsighted.', // Changed to 'clue'
    ),
    Clue(
      id: 'A9',
      number: 9,
      direction: Direction.across,
      startRow: 8,
      startCol: 4,
      answer: 'ASTOUND',
      clue: '(v.) to surprise or impress someone greatly.', // Changed to 'clue'
    ),
    Clue(
      id: 'A11',
      number: 11,
      direction: Direction.across,
      startRow: 10,
      startCol: 0,
      answer: 'SCOFF',
      clue:
          '(v.) to ridicule or mock someone or something in a cruel or contemptuous (=not showing respect) way.', // Changed to 'clue'
    ),
    Clue(
      id: 'A12',
      number: 12,
      direction: Direction.across,
      startRow: 11,
      startCol: 0,
      answer: 'SABOTAGE',
      clue: '(v.) to weaken or undermine', // Changed to 'clue'
    ),

    // DOWN
    Clue(
      id: 'D2',
      number: 2,
      direction: Direction.down,
      startRow: 1, // moved off top row to avoid A1 conflicts
      startCol: 2,
      answer: 'REPERTOIRE',
      clue:
          '(n.) the range of skills or types of behavior that a person habitually uses.', // Changed to 'clue'
    ),
    Clue(
      id: 'D3',
      number: 3,
      direction: Direction.down,
      startRow: 1, // moved off top row to avoid A1 conflicts
      startCol: 7,
      answer: 'DIFFUSION',
      clue:
          '(n.) Spreading widely throughout an area or group of people.', // Changed to 'clue'
    ),
    Clue(
      id: 'D4',
      number: 4,
      direction: Direction.down,
      startRow: 1, // moved off top row and shortened to fit
      startCol: 4,
      answer: 'DEPICTION',
      clue:
          '(n.) the description of someone or something in a particular way.', // normalized length
    ),
    Clue(
      id: 'D8',
      number: 8,
      direction: Direction.down,
      startRow: 6,
      startCol: 8,
      answer: 'CONSTRAINT',
      clue: '(n.) a limitation or restriction', // Changed to 'clue'
    ),
    Clue(
      id: 'D10',
      number: 10,
      direction: Direction.down,
      startRow: 9,
      startCol: 7,
      answer: 'CANDOR',
      clue: '(n.) the quality of being frank and honest', // Changed to 'clue'
    ),
  ],
);

// --- Level 2 Data (Based on image (4).png) ---
final CrosswordLevel level3 = CrosswordLevel(
  id: '3', // Changed to String ID
  rows: 7,
  cols: 10,
  clues: [
    // ACROSS
    Clue(
      id: 'A1',
      number: 1,
      direction: Direction.across,
      startRow: 0,
      startCol: 0,
      answer: 'RESIDUAL',
      clue:
          '(adj.) remaining after the main part is gone or dealt with', // Changed to 'clue'
    ),
    Clue(
      id: 'A3',
      number: 3,
      direction: Direction.across,
      startRow: 3,
      startCol: 0,
      answer: 'AMPLIFY',
      clue:
          '(v.) to exaggerate or make something seem more significant than it really is.', // Changed to 'clue'
    ),
    Clue(
      id: 'A5',
      number: 5,
      direction: Direction.across,
      startRow: 5,
      startCol: 0,
      answer: 'INTENSIFY',
      clue: '(adj.) increasing in intensity or degree', // Changed to 'clue'
    ),
    Clue(
      id: 'A6',
      number: 6,
      direction: Direction.across,
      startRow: 6,
      startCol: 0,
      answer: 'MACABRE',
      clue:
          '(adj.) treating serious issues with deliberately inappropriate humor', // Changed to 'clue'
    ),

    // DOWN
    Clue(
      id: 'D2',
      number: 2,
      direction: Direction.down,
      startRow: 0,
      startCol: 9,
      answer: 'ENTWINE',
      clue: '(v.) to twist together; interlace',
    ),
    Clue(
      id: 'D4',
      number: 4,
      direction: Direction.down,
      startRow: 3,
      startCol: 4,
      answer: 'HARMONY',
      clue:
          '(n.) combination of different elements smoothly or harmoniously.', // Changed to 'clue'
    ),
  ],
);

// --- Level 3 Data (Based on image (5).png) ---
CrosswordLevel level4 = CrosswordLevel(
  id: '4', // Changed to String ID
  rows: 9,
  cols: 12,
  clues: [
    // ACROSS
    Clue(
      id: 'A1',
      number: 1,
      direction: Direction.across,
      startRow: 0,
      startCol: 0,
      answer: 'IDEALISTIC',
      clue:
          '(adj.) believes that it is possible to live according to very high standards of behavior and honesty', // Changed to 'clue'
    ),
    Clue(
      id: 'A3',
      number: 3,
      direction: Direction.across,
      startRow: 3,
      startCol: 0,
      answer: 'GULLIBLE',
      clue:
          '(n.) A person who is easily deceived or lacks common sense', // Changed to 'clue'
    ),
    Clue(
      id: 'A6',
      number: 6,
      direction: Direction.across,
      startRow: 5,
      startCol: 6,
      answer: 'MELLOW',
      clue: '(adj.) (of sound) deep, loud and pleasant', // Changed to 'clue'
    ),
    Clue(
      id: 'A8',
      number: 8,
      direction: Direction.across,
      startRow: 7,
      startCol: 0,
      answer: 'CYNIC',
      clue:
          '(n.) a person who believes that people are motivated purely by self-interest and distrusts others’ sincerity or goodness.', // Changed to 'clue'
    ),
    Clue(
      id: 'A9',
      number: 9,
      direction: Direction.across,
      startRow: 8,
      startCol: 6,
      answer: 'COVETOUS',
      clue:
          '(adj.) unpleasant and likely to cause bad feelings in other people; causing envy', // Changed to 'clue'
    ),

    // DOWN
    Clue(
      id: 'D1',
      number: 1,
      direction: Direction.down,
      startRow: 0,
      startCol: 0,
      answer: 'INSIDIOUS',
      clue:
          '(adj.) harming gradually or indirectly (that is not easily noticed)', // Changed to 'clue'
    ),
    Clue(
      id: 'D2',
      number: 2,
      direction: Direction.down,
      startRow: 0,
      startCol: 2,
      answer: 'ZEALOT',
      clue:
          '(n.) someone who adheres to a set of beliefs very rigidly and promotes them passionately.', // Changed to 'clue'
    ),
    Clue(
      id: 'D4',
      number: 4,
      direction: Direction.down,
      startRow: 3,
      startCol: 3,
      answer: 'VENAL',
      clue:
          '(adj.) motivated by money or personal gain rather than moral principles.', // Changed to 'clue'
    ),
    Clue(
      id: 'D5',
      number: 5,
      direction: Direction.down,
      startRow: 0,
      startCol: 5,
      answer: 'SKEPTICISM',
      clue: '(n.) a feeling of doubt or apprehension', // Changed to 'clue'
    ),
    Clue(
      id: 'D7',
      number: 7,
      direction: Direction.down,
      startRow: 6,
      startCol: 8,
      answer: 'ABOUND',
      clue:
          '(v.) to exist or occur in large numbers or amounts.', // Changed to 'clue'
    ),
  ],
);

CrosswordLevel level5 = CrosswordLevel(
  id: '5',
   rows:5,
    cols: 5,
     clues: [
      Clue(
        id: 'A1',
         number: 1,
          direction: Direction.across,
           clue: '(n.)deep understanding or judgement', 
           answer: '', 
           startRow: 0, 
           startCol: 0)

     ]
);


final List<CrosswordLevel> allLevels = [
  level1, 
  level2,
  level3,
  level4,
];
