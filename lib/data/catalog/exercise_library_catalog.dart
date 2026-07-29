import '../models/exercise_model.dart';
import 'exercise_coaching.dart';

/// The general exercise library: everything in the exercise sheet that is not
/// a step of a skill tree — barbell and dumbbell work, machines, isolation,
/// power and carries.
///
/// These are loggable but outside the progressions. Nothing unlocks them and
/// they unlock nothing, so program generation never reaches for one; they are
/// found by searching, added to a day by hand, and advanced by asking, the
/// way the barbell lifts already are.
///
/// Generated from the sheet. The how-to steps are its own sentences, split
/// into bullets; the tree catalog's steps were written by hand.
class ExerciseLibraryCatalog {
  ExerciseLibraryCatalog._();

  static const List<Exercise> _all = [
    Exercise(
      id: 'Farmers_Walk',
      category: ExerciseCategory.other,
      muscles: ['Forearms', 'Traps', 'Core', 'Glutes'],
      name: 'Farmer\'s Walk',
      description:
          'Grip a heavy implement or a dumbbell in each hand at your sides, brace, and stand tall by driving through the heels.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Farmers_Walk/0.jpg',
    ),
    Exercise(
      id: 'Rickshaw_Carry',
      category: ExerciseCategory.other,
      muscles: ['Forearms', 'Traps', 'Core', 'Glutes'],
      name: 'Rickshaw Carry',
      description:
          'Stand centered inside the frame and grip the handles at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rickshaw_Carry/0.jpg',
    ),
    Exercise(
      id: 'Yoke_Walk',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Forearms', 'Traps', 'Core', 'Glutes'],
      name: 'Yoke Walk',
      description:
          'Duck under the yoke and rack the crossbar across the back of your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Yoke_Walk/0.jpg',
    ),
    Exercise(
      id: 'Dead_Bug',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Dead Bug',
      description:
          'Lie on your back with arms reaching toward the ceiling and knees bent over your hips at 90 degrees.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dead_Bug/0.jpg',
    ),
    Exercise(
      id: 'Pallof_Press',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Pallof Press',
      description:
          'Set a cable handle to shoulder height and stand side-on, holding it at your chest with both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pallof_Press/0.jpg',
    ),
    Exercise(
      id: 'Plank',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Plank',
      description:
          'Rest on the forearms and toes with the elbows directly under the shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plank/0.jpg',
    ),
    Exercise(
      id: 'Ab_Crunch_Machine',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Ab Crunch Machine',
      description:
          'Sit on the machine with your feet hooked under the pads and grab the top handles.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ab_Crunch_Machine/0.jpg',
    ),
    Exercise(
      id: 'Air_Bike',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Air Bike',
      description:
          'Lie on your back with hands lightly beside your head and lift your shoulders off the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Air_Bike/0.jpg',
    ),
    Exercise(
      id: 'Alternate_Heel_Touchers',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Alternate Heel Touchers',
      description:
          'Lie on your back with knees bent, feet flat and shoulder-width apart, and arms extended at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Heel_Touchers/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Rollout_from_Bench',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Barbell Rollout from Bench',
      description:
          'Kneel on a bench and take a narrow grip on a loaded barbell resting on the floor at the bench\'s end.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Rollout_from_Bench/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Side_Bend',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Barbell Side Bend',
      description:
          'Stand with a barbell resting across the back of your shoulders and feet shoulder-width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Side_Bend/0.jpg',
    ),
    Exercise(
      id: 'Bent_Press',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Bent Press',
      description:
          'Clean a kettlebell to your shoulder and turn the wrist in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Press/0.jpg',
    ),
    Exercise(
      id: 'Bent-Knee_Hip_Raise',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Bent-Knee Hip Raise',
      description:
          'Lie flat with arms at your sides and knees bent to about 75 degrees, feet hovering off the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent-Knee_Hip_Raise/0.jpg',
    ),
    Exercise(
      id: 'Bosu_Ball_Cable_Crunch_With_Side_Bends',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Bosu Ball Cable Crunch With Side Bends',
      description:
          'Set two low cable handles and lie back over a Bosu ball centered in front of the machine, holding a handle by each side of your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bosu_Ball_Cable_Crunch_With_Side_Bends/0.jpg',
    ),
    Exercise(
      id: 'Bottoms_Up',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Bottoms Up',
      description:
          'Lie on your back with legs straight and arms at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bottoms_Up/0.jpg',
    ),
    Exercise(
      id: 'Butt-Ups',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Butt-Ups',
      description:
          'Set up in a forearm plank with elbows under your shoulders and your back slightly arched.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Butt-Ups/0.jpg',
    ),
    Exercise(
      id: 'Cable_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cable Crunch',
      description:
          'Kneel below a high pulley holding the rope by the head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Cable_Judo_Flip',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cable Judo Flip',
      description:
          'Set a rope on the lowest pulley and stand side-on with a wide stance, gripping it with both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Judo_Flip/0.jpg',
    ),
    Exercise(
      id: 'Cable_Reverse_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cable Reverse Crunch',
      description:
          'Attach an ankle strap to a low pulley and lie on a mat with your feet toward the machine, knees bent to 90 degrees and legs lifted.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Reverse_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Cable_Seated_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cable Seated Crunch',
      description:
          'Sit on a bench with your back to a high pulley and hold the rope with both hands beside your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Seated_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Cocoons',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cocoons',
      description:
          'Lie on your back with your legs straight and arms extended overhead.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cocoons/0.jpg',
    ),
    Exercise(
      id: 'Cross-Body_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cross-Body Crunch',
      description:
          'Lie on your back with your knees bent and feet flat, hands loose behind your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cross-Body_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Crunch_-_Hands_Overhead',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Crunch - Hands Overhead',
      description:
          'Lie on your back with your knees bent and feet flat, arms stretched overhead with palms crossed.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crunch_-_Hands_Overhead/0.jpg',
    ),
    Exercise(
      id: 'Crunch_-_Legs_On_Exercise_Ball',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Crunch - Legs On Exercise Ball',
      description:
          'Lie on your back with your feet resting on an exercise ball, knees bent to 90 degrees and hands beside your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crunch_-_Legs_On_Exercise_Ball/0.jpg',
    ),
    Exercise(
      id: 'Crunches',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Crunches',
      description:
          'Lie on your back with your knees bent and feet flat, holding a medicine ball against your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crunches/0.jpg',
    ),
    Exercise(
      id: 'Decline_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Decline Crunch',
      description:
          'Hook your legs at the top of a decline bench and lie back with your hands beside your head, elbows in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Decline_Oblique_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Decline Oblique Crunch',
      description:
          'Hook your legs on a decline bench and lie back with one hand beside your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Oblique_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Decline_Reverse_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Decline Reverse Crunch',
      description:
          'Lie head-up on a decline bench and grip the top behind your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Reverse_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Elbow_to_Knee',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Elbow to Knee',
      description:
          'Lie on your back and cross one ankle over the opposite bent knee, hands behind your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elbow_to_Knee/0.jpg',
    ),
    Exercise(
      id: 'Exercise_Ball_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Exercise Ball Crunch',
      description:
          'Lie back over an exercise ball with your lower back on the curve and feet flat on the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Exercise_Ball_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Exercise_Ball_Pull-In',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Exercise Ball Pull-In',
      description:
          'Get into a push-up position with your hands on the floor and shins on top of an exercise ball, body straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Exercise_Ball_Pull-In/0.jpg',
    ),
    Exercise(
      id: 'Flat_Bench_Leg_Pull-In',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Flat Bench Leg Pull-In',
      description:
          'Lie back on a flat bench with your legs extended off the end, hands under your glutes or gripping the bench.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Leg_Pull-In/0.jpg',
    ),
    Exercise(
      id: 'Flat_Bench_Lying_Leg_Raise',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Flat Bench Lying Leg Raise',
      description:
          'Lie flat on a bench with your legs extended off the end and grip the bench beside your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Lying_Leg_Raise/0.jpg',
    ),
    Exercise(
      id: 'Frog_Sit-Ups',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Frog Sit-Ups',
      description:
          'Lie on your back with knees dropped out to the sides and the soles of your feet together.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Frog_Sit-Ups/0.jpg',
    ),
    Exercise(
      id: 'Gorilla_Chin_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Gorilla Chin/Crunch',
      description:
          'Hang from a chin-up bar with an underhand grip slightly wider than your shoulders and knees bent to 90 degrees.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Gorilla_Chin_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Hanging_Pike',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Hanging Pike',
      description:
          'Hang from a chin-up bar with an overhand grip slightly wider than your shoulders and legs together.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Pike/0.jpg',
    ),
    Exercise(
      id: 'Jackknife_Sit-Up',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Jackknife Sit-Up',
      description:
          'Lie flat with your arms extended overhead and legs straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jackknife_Sit-Up/0.jpg',
    ),
    Exercise(
      id: 'Janda_Sit-Up',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Janda Sit-Up',
      description:
          'Lie on your back with knees bent 90 degrees, feet flat, and arms crossed over your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Janda_Sit-Up/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Figure_8',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Kettlebell Figure 8',
      description:
          'Take a wider than shoulder-width stance and hinge at the hips with a flat back, holding a kettlebell in one hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Figure_8/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Pass_Between_The_Legs',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Kettlebell Pass Between The Legs',
      description:
          'Take a comfortable stance and hinge at the hips with your back flat, holding a kettlebell between your legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Pass_Between_The_Legs/0.jpg',
    ),
    Exercise(
      id: 'Knee_Hip_Raise_On_Parallel_Bars',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Knee/Hip Raise On Parallel Bars',
      description:
          'Support yourself on the raise station with your forearms on the pads and back against the rest, legs hanging straight down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Knee_Hip_Raise_On_Parallel_Bars/0.jpg',
    ),
    Exercise(
      id: 'Landmine_180s',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Landmine 180\'s',
      description:
          'Anchor a barbell in a landmine and raise the loaded end to shoulder height with both hands, arms extended, in a wide stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Landmine_180s/0.jpg',
    ),
    Exercise(
      id: 'Leg_Pull-In',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Leg Pull-In',
      description:
          'Lie on a mat with legs extended and hands beside your hips or under your glutes.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Pull-In/0.jpg',
    ),
    Exercise(
      id: 'Oblique_Crunches',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Oblique Crunches',
      description:
          'Lie on your back with feet elevated on a bench, one hand beside your head and the other out on the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Oblique_Crunches/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_High-Pulley_Cable_Side_Bends',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'One-Arm High-Pulley Cable Side Bends',
      description:
          'Set a handle to the highest pulley and stand side-on to the machine.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_High-Pulley_Cable_Side_Bends/0.jpg',
    ),
    Exercise(
      id: 'Otis-Up',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Otis-Up',
      description:
          'Secure your feet and lie back with your knees bent, holding a weight at your chest with both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Otis-Up/0.jpg',
    ),
    Exercise(
      id: 'Press_Sit-Up',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Press Sit-Up',
      description:
          'Lie back with your legs secured and a barbell resting on your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Press_Sit-Up/0.jpg',
    ),
    Exercise(
      id: 'Rope_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Rope Crunch',
      description:
          'Kneel facing a high cable, grasp the rope overhead with both hands, and hold it beside your head with your torso upright.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Seated_Flat_Bench_Leg_Pull-In',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Seated Flat Bench Leg Pull-In',
      description:
          'Sit on the end of a bench, grip the sides, and lean your torso back about 45 degrees with your legs extended straight and slightly below parallel.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Flat_Bench_Leg_Pull-In/0.jpg',
    ),
    Exercise(
      id: 'Seated_Leg_Tucks',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Seated Leg Tucks',
      description:
          'Sit on a bench gripping the edges, torso leaning back near 45 degrees with legs stretched out below parallel.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Leg_Tucks/0.jpg',
    ),
    Exercise(
      id: 'Side_Bridge',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Side Bridge',
      description:
          'Lie on one side with the forearm under the shoulder and legs stacked.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Bridge/0.jpg',
    ),
    Exercise(
      id: 'Side_Jackknife',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Side Jackknife',
      description:
          'Lie on one side with legs extended and the top hand behind the head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Jackknife/0.jpg',
    ),
    Exercise(
      id: 'Sit-Up',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Sit-Up',
      description:
          'Lie on your back with knees bent, feet anchored, and hands behind your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sit-Up/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Hip_Raise',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Smith Machine Hip Raise',
      description:
          'Lie on a bench set in a Smith machine and rest the bar against the soles of your feet with your legs extended up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Hip_Raise/0.jpg',
    ),
    Exercise(
      id: 'Spell_Caster',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Spell Caster',
      description:
          'Stand with feet wide, holding a dumbbell in each hand with a palms-down grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Spell_Caster/0.jpg',
    ),
    Exercise(
      id: 'Spider_Crawl',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Spider Crawl',
      description:
          'Get into a low push-up plank with your arms bent and body straight from head to heels.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Spider_Crawl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Cable_Lift',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Standing Cable Lift',
      description:
          'Set the cable to the lowest pulley and stand side-on, gripping the handle with both hands by your outside hip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Cable_Lift/0.jpg',
    ),
    Exercise(
      id: 'Standing_Rope_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Standing Rope Crunch',
      description:
          'Set a rope on a high pulley and stand with your back to the tower, holding the rope over your shoulders with the ends at your upper chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Rope_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Suspended_Fallout',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Suspended Fallout',
      description:
          'Set suspension straps below waist height, grab a handle in each hand, and lean forward into an incline plank with arms extended in front.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Fallout/0.jpg',
    ),
    Exercise(
      id: 'Suspended_Reverse_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Suspended Reverse Crunch',
      description:
          'Place your feet in suspension handles set about a foot off the floor and get into a push-up plank facing away from the rack.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Reverse_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Tuck_Crunch',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Tuck Crunch',
      description:
          'Lie on your back with your knees bent up and ankles crossed, arms resting at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tuck_Crunch/0.jpg',
    ),
    Exercise(
      id: 'Weighted_Ball_Side_Bend',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Weighted Ball Side Bend',
      description:
          'Drape one side of your torso over an exercise ball with your feet planted for support, holding a weight plate against the side of your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Ball_Side_Bend/0.jpg',
    ),
    Exercise(
      id: 'Weighted_Sit-Ups_-_With_Bands',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Weighted Sit-Ups - With Bands',
      description:
          'Anchor bands at the base of a decline bench, hook your legs under the pads, and lie back holding a handle at each shoulder.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Sit-Ups_-_With_Bands/0.jpg',
    ),
    Exercise(
      id: 'Wind_Sprints',
      category: ExerciseCategory.core,
      muscles: ['Core', 'Cardio'],
      name: 'Wind Sprints',
      description:
          'Hang from a pull-up bar with an overhand grip and arms and legs fully extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wind_Sprints/0.jpg',
    ),
    Exercise(
      id: 'Advanced_Kettlebell_Windmill',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Advanced Kettlebell Windmill',
      description:
          'Clean and press a kettlebell overhead and lock it out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Advanced_Kettlebell_Windmill/0.jpg',
    ),
    Exercise(
      id: 'Cable_Russian_Twists',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Cable Russian Twists',
      description:
          'Set a handle to a middle pulley and lie back on a stability ball with your side to the cable.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Russian_Twists/0.jpg',
    ),
    Exercise(
      id: 'Double_Kettlebell_Windmill',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Double Kettlebell Windmill',
      description:
          'Press one kettlebell overhead and lock it out, with a second bell resting by your front foot.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Windmill/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Windmill',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Kettlebell Windmill',
      description:
          'Clean and press a kettlebell overhead and lock the arm out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Windmill/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_Cable_Crunch_With_Alternating_Oblique_Twists',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Kneeling Cable Crunch With Alternating Oblique Twists',
      description:
          'Attach a rope to a high pulley and kneel a couple of feet back, holding the rope beside your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Cable_Crunch_With_Alternating_Oblique_Twists/0.jpg',
    ),
    Exercise(
      id: 'Pallof_Press_With_Rotation',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Pallof Press With Rotation',
      description:
          'Set a handle to shoulder height and stand side-on, holding it at your chest with both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pallof_Press_With_Rotation/0.jpg',
    ),
    Exercise(
      id: 'Plate_Twist',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Plate Twist',
      description:
          'Sit on the floor with your torso upright and hold a plate by its sides in front of your stomach.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plate_Twist/0.jpg',
    ),
    Exercise(
      id: 'Russian_Twist',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Russian Twist',
      description:
          'Sit with the knees bent and torso leaned back, feet up or down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Russian_Twist/0.jpg',
    ),
    Exercise(
      id: 'Seated_Barbell_Twist',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Seated Barbell Twist',
      description:
          'Sit on the end of a flat bench with your feet shoulder-width apart and a barbell resting across the back of your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Barbell_Twist/0.jpg',
    ),
    Exercise(
      id: 'Standing_Cable_Wood_Chop',
      category: ExerciseCategory.core,
      muscles: ['Core'],
      name: 'Standing Cable Wood Chop',
      description:
          'Set a handle to the top pulley and stand side-on, gripping it with both hands and arms extended up toward the tower.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Cable_Wood_Chop/0.jpg',
    ),
    Exercise(
      id: 'Atlas_Stone_Trainer',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Atlas Stone Trainer',
      description:
          'Load the trainer and straddle it with feet hip-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Atlas_Stone_Trainer/0.jpg',
    ),
    Exercise(
      id: 'Atlas_Stones',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Atlas Stones',
      description:
          'Stand over the stone with it between your feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Atlas_Stones/0.jpg',
    ),
    Exercise(
      id: 'Axle_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Axle Deadlift',
      description:
          'Set your feet hip-width with the axle over your midfoot.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Axle_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Band_Good_Morning_Pull_Through',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Band Good Morning ',
      description:
          'Loop a band around a sturdy post and hook the other end behind your neck.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Good_Morning_Pull_Through/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Barbell Deadlift',
      description:
          'Set the bar over the mid-foot, hip-width stance, and grip just outside the knees.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Glute_Bridge',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Barbell Glute Bridge',
      description:
          'Lie on the floor with the bar across the hips and knees bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Glute_Bridge/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Hip_Thrust',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Barbell Hip Thrust',
      description:
          'Sit with the upper back on a bench and the bar across the hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Hip_Thrust/0.jpg',
    ),
    Exercise(
      id: 'Cable_Deadlifts',
      category: ExerciseCategory.hinge,
      muscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Cable Deadlifts',
      description:
          'Set both cables to the lowest pulleys and stand between the towers.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Deadlifts/0.jpg',
    ),
    Exercise(
      id: 'Car_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Car Deadlift',
      description:
          'Center yourself in the frame and take the neutral-grip handles at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Car_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Clean_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Clean Deadlift',
      description:
          'Set your feet hip-width under the bar with toes turned out slightly, and take a shoulder-width overhand or hook grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Deadlift_with_Chains',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Deadlift with Chains',
      description:
          'Drape chains over the bar or clip them to the sleeves so the load builds as you rise.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Deadlift_with_Chains/0.jpg',
    ),
    Exercise(
      id: 'Deficit_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Deficit Deadlift',
      description:
          'Stand on a platform one to three inches high with the bar over your midfoot and feet hip-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Deficit_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Flutter_Kicks',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Flutter Kicks',
      description:
          'Lie facedown on a bench with your hips at the edge and hold the front for support.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flutter_Kicks/0.jpg',
    ),
    Exercise(
      id: 'Glute_Ham_Raise',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Glute Ham Raise',
      description:
          'Set your feet against the footplate between the rollers and lie facedown with your knees just behind the pad.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Glute_Ham_Raise/0.jpg',
    ),
    Exercise(
      id: 'Good_Morning',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Good Morning',
      description:
          'With the bar on the upper back and knees soft, push the hips back and hinge the torso toward parallel with a flat back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Good_Morning/0.jpg',
    ),
    Exercise(
      id: 'Good_Morning_off_Pins',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Good Morning off Pins',
      description:
          'Set the bar on pins at stomach height and rack it across the rear of your shoulders with a hip-width stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Good_Morning_off_Pins/0.jpg',
    ),
    Exercise(
      id: 'Hanging_Bar_Good_Morning',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Hanging Bar Good Morning',
      description:
          'Suspend the bar from chains or straps at stomach height and rack it across the rear of your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Bar_Good_Morning/0.jpg',
    ),
    Exercise(
      id: 'Hip_Extension_with_Bands',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Hip Extension with Bands',
      description:
          'Attach a band to a low post and secure the other end to one ankle.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hip_Extension_with_Bands/0.jpg',
    ),
    Exercise(
      id: 'Hip_Lift_with_Band',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Hip Lift with Band',
      description:
          'Lie on your back in the middle of the rack with a band anchored on both sides running across your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hip_Lift_with_Band/0.jpg',
    ),
    Exercise(
      id: 'Hyperextensions_Back_Extensions',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Hyperextensions (Back Extensions)',
      description:
          'Lie facedown on a hyperextension bench with your ankles secured under the footpads and thighs flat across the pad.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hyperextensions_Back_Extensions/0.jpg',
    ),
    Exercise(
      id: 'Hyperextensions_With_No_Hyperextension_Bench',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Hyperextensions With No Hyperextension Bench',
      description:
          'Lie facedown on a flat bench with your hips at the edge and a partner holding your legs down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hyperextensions_With_No_Hyperextension_Bench/0.jpg',
    ),
    Exercise(
      id: 'Keg_Load',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Keg Load',
      description:
          'Set the keg on its side and grip the near edge of the base, tilting it toward you to grab the far bottom edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Keg_Load/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_One-Legged_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Kettlebell One-Legged Deadlift',
      description:
          'Hold a kettlebell in one hand and stand on the same-side leg with a soft knee.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_One-Legged_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Leverage Deadlift',
      description:
          'Load the machine and stand between the handles with feet hip-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Natural_Glute_Ham_Raise',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Natural Glute Ham Raise',
      description:
          'Anchor your ankles under the pads of a lat pulldown or preacher bench, knees on the seat, facing away and upright.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Natural_Glute_Ham_Raise/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Swings',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'One-Arm Kettlebell Swings',
      description:
          'Stand with the kettlebell an arm\'s length in front, hinge at the hips and hike it back between the legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Swings/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Side_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'One-Arm Side Deadlift',
      description:
          'Stand alongside a loaded barbell with your feet next to its center.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Side_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Physioball_Hip_Bridge',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Physioball Hip Bridge',
      description:
          'Lie with your upper back on an exercise ball and feet flat on the floor, hip width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Physioball_Hip_Bridge/0.jpg',
    ),
    Exercise(
      id: 'Power_Stairs',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core', 'Cardio'],
      name: 'Power Stairs',
      description:
          'Set your feet wide and grip the implement with both hands, head and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Stairs/0.jpg',
    ),
    Exercise(
      id: 'Prowler_Sprint',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core', 'Cardio'],
      name: 'Prowler Sprint',
      description:
          'Load the sled and grip the upright or low handles with your arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Prowler_Sprint/0.jpg',
    ),
    Exercise(
      id: 'Pull_Through',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Pull Through',
      description:
          'Straddle a low cable with a rope attachment, facing away a few feet from the machine with your feet set wide.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pull_Through/0.jpg',
    ),
    Exercise(
      id: 'Rack_Pull_with_Bands',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Rack Pull with Bands',
      description:
          'Set the bar on pins just below or above the knees in a power rack and anchor bands from the bar to the rack base.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rack_Pull_with_Bands/0.jpg',
    ),
    Exercise(
      id: 'Rack_Pulls',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Rack Pulls',
      description:
          'Set the bar on pins just below or above the knees in a power rack.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rack_Pulls/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Band_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Reverse Band Deadlift',
      description:
          'Attach bands from the top of the rack to the bar so they take tension off the bottom of the lift.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Band_Sumo_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Reverse Band Sumo Deadlift',
      description:
          'Anchor bands from the top of the rack to the barbell so they unload the bottom.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Sumo_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Rickshaw_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Rickshaw Deadlift',
      description:
          'Stand centered inside a loaded rickshaw frame with your feet hip width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rickshaw_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Romanian_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Romanian Deadlift',
      description:
          'Hold the bar at hip height with an overhand grip just wider than the shoulders, knees soft and shins vertical.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Romanian_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Romanian_Deadlift_from_Deficit',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Romanian Deadlift from Deficit',
      description:
          'Stand on a raised platform holding a barbell at your thighs with knees slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Romanian_Deadlift_from_Deficit/0.jpg',
    ),
    Exercise(
      id: 'Seated_Good_Mornings',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Seated Good Mornings',
      description:
          'Sit on a box set in a power rack with the bar across your rear delts, not your neck.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Good_Mornings/0.jpg',
    ),
    Exercise(
      id: 'Single_Leg_Glute_Bridge',
      category: ExerciseCategory.hinge,
      muscles: ['Glutes', 'Hamstrings', 'Lower back', 'Core'],
      name: 'Single Leg Glute Bridge',
      description:
          'Lie on your back with feet flat and knees bent, then lift one knee toward your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Leg_Glute_Bridge/0.jpg',
    ),
    Exercise(
      id: 'Snatch_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Snatch Deadlift',
      description:
          'Take a wide snatch grip on a barbell with your feet under your hips, toes turned out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Stiff_Leg_Barbell_Good_Morning',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Stiff Leg Barbell Good Morning',
      description:
          'Set the bar across the back of your shoulders in a squat rack and step out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stiff_Leg_Barbell_Good_Morning/0.jpg',
    ),
    Exercise(
      id: 'Stiff-Legged_Barbell_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Stiff-Legged Barbell Deadlift',
      description:
          'With soft knees, hinge at the hips and lower the bar down the front of the legs, keeping the back flat until you feel a hamstring stretch.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stiff-Legged_Barbell_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Sumo_Deadlift_with_Bands',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Sumo Deadlift with Bands',
      description:
          'Loop bands over the bar and stand on them with a wide sumo stance, toes turned out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sumo_Deadlift_with_Bands/0.jpg',
    ),
    Exercise(
      id: 'Sumo_Deadlift_with_Chains',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Sumo Deadlift with Chains',
      description:
          'Drape chains over the barbell so more links lift off the floor as you rise.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sumo_Deadlift_with_Chains/0.jpg',
    ),
    Exercise(
      id: 'Trap_Bar_Deadlift',
      category: ExerciseCategory.hinge,
      muscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Trap Bar Deadlift',
      description:
          'Stand in the center of a loaded trap bar and grip both handles.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Trap_Bar_Deadlift/0.jpg',
    ),
    Exercise(
      id: 'Weighted_Ball_Hyperextension',
      category: ExerciseCategory.hinge,
      muscles: ['Lower back', 'Hamstrings', 'Glutes', 'Core'],
      name: 'Weighted Ball Hyperextension',
      description:
          'Lie face down over an exercise ball with your torso parallel to the floor and the balls of your feet planted for balance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Ball_Hyperextension/0.jpg',
    ),
    Exercise(
      id: 'Wide_Stance_Stiff_Legs',
      category: ExerciseCategory.hinge,
      muscles: ['Hamstrings', 'Glutes', 'Lower back', 'Core'],
      name: 'Wide Stance Stiff Legs',
      description:
          'Set a wide stance over a loaded barbell and hinge at the hips to grip it, legs nearly straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide_Stance_Stiff_Legs/0.jpg',
    ),
    Exercise(
      id: 'Alternating_Kettlebell_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Alternating Kettlebell Row',
      description:
          'Set two kettlebells in front of your feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Kettlebell_Row/0.jpg',
    ),
    Exercise(
      id: 'Alternating_Renegade_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Alternating Renegade Row',
      description:
          'Grip two kettlebells on the floor at shoulder width and set up in a pushup plank on the handles, body straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Renegade_Row/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Rear_Delt_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Shoulders',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Barbell Rear Delt Row',
      description:
          'Hold a barbell with a wide overhand grip and hinge forward, keeping the natural arch in your back and knees slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Rear_Delt_Row/0.jpg',
    ),
    Exercise(
      id: 'Bent_Over_One-Arm_Long_Bar_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Bent Over One-Arm Long Bar Row',
      description:
          'Wedge one end of a barbell into a corner and load the other end.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_One-Arm_Long_Bar_Row/0.jpg',
    ),
    Exercise(
      id: 'Bent_Over_Two-Arm_Long_Bar_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Bent Over Two-Arm Long Bar Row',
      description:
          'Wedge one end of a barbell into a corner and load the other end.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Two-Arm_Long_Bar_Row/0.jpg',
    ),
    Exercise(
      id: 'Bent_Over_Two-Dumbbell_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Bent Over Two-Dumbbell Row',
      description:
          'Hold a dumbbell in each hand and hinge forward at the waist, knees slightly bent, back flat until your torso is almost parallel to the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Two-Dumbbell_Row/0.jpg',
    ),
    Exercise(
      id: 'Bent_Over_Two-Dumbbell_Row_With_Palms_In',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Bent Over Two-Dumbbell Row With Palms In',
      description:
          'Hold a dumbbell in each hand with palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Two-Dumbbell_Row_With_Palms_In/0.jpg',
    ),
    Exercise(
      id: 'Bodyweight_Mid_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Bodyweight Mid Row',
      description:
          'Take a medium to wide overhand grip on a pull-up bar and hang.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Mid_Row/0.jpg',
    ),
    Exercise(
      id: 'Cable_Rope_Rear-Delt_Rows',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Shoulders',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Cable Rope Rear-Delt Rows',
      description:
          'Sit at a low pulley row station and attach a rope, gripping it overhand with arms extended parallel to the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Rope_Rear-Delt_Rows/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Incline_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Dumbbell Incline Row',
      description:
          'Set an incline bench and lie chest-down against it with a dumbbell in each hand, neutral grip, arms hanging straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Incline_Row/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_One-Arm_Upright_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Shoulders',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Dumbbell One-Arm Upright Row',
      description:
          'Stand tall holding a dumbbell in front of your thigh with your arm straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_One-Arm_Upright_Row/0.jpg',
    ),
    Exercise(
      id: 'Elevated_Cable_Rows',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Elevated Cable Rows',
      description:
          'Place a low platform on the seat of a cable row machine and sit on it so you are elevated, feet on the front crossbar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elevated_Cable_Rows/0.jpg',
    ),
    Exercise(
      id: 'Face_Pull',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Shoulders',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Face Pull',
      description:
          'Set a rope on a high pulley and grab both ends with palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Face_Pull/0.jpg',
    ),
    Exercise(
      id: 'Gironda_Sternum_Chins',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Gironda Sternum Chins',
      description:
          'Grip the bar with a shoulder-width underhand hold and hang with your chest up and body leaning back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Gironda_Sternum_Chins/0.jpg',
    ),
    Exercise(
      id: 'Inverted_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Inverted Row',
      description:
          'Set a bar in a rack at about waist height and hang underneath it with a wider than shoulder-width grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    Exercise(
      id: 'Inverted_Row_with_Straps',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Inverted Row with Straps',
      description:
          'Hang suspension straps from a rack and grab a handle in each hand, positioning yourself face-up with arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row_with_Straps/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Sumo_High_Pull',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Traps', 'Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Kettlebell Sumo High Pull',
      description:
          'Stand in a wide sumo stance with a kettlebell between your feet and grip it with both hands, hips set back and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Sumo_High_Pull/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_High_Pulley_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Kneeling High Pulley Row',
      description:
          'Attach a rope to a high pulley and kneel a couple of feet back, holding both ends with your arms extended toward the pulley.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_High_Pulley_Row/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_Single-Arm_High_Pulley_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Kneeling Single-Arm High Pulley Row',
      description:
          'Attach a single handle to a high pulley and kneel in front of it, taking the handle in one hand with your arm extended overhead and palm facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Single-Arm_High_Pulley_Row/0.jpg',
    ),
    Exercise(
      id: 'Leverage_High_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Leverage High Row',
      description:
          'Adjust the seat so you can just reach the overhead handles and lock your knees under the pad.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_High_Row/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Iso_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Leverage Iso Row',
      description:
          'Adjust the seat so the handles sit at chest level and grip them with a neutral or overhand hold, chest against the pad.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Iso_Row/0.jpg',
    ),
    Exercise(
      id: 'London_Bridges',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'London Bridges',
      description:
          'Anchor a climbing rope overhead and stand on a locked bar or box, gripping the rope with both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/London_Bridges/0.jpg',
    ),
    Exercise(
      id: 'Low_Pulley_Row_To_Neck',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Shoulders',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Low Pulley Row To Neck',
      description:
          'Sit at a low pulley with a rope attachment and hold the ends with a palms-down grip, back upright and arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Low_Pulley_Row_To_Neck/0.jpg',
    ),
    Exercise(
      id: 'Lying_Cambered_Barbell_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Lying Cambered Barbell Row',
      description:
          'Lie face down on a bench with a cambered barbell on the floor beneath you and grab it with a wide overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Cambered_Barbell_Row/0.jpg',
    ),
    Exercise(
      id: 'Lying_T-Bar_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Lying T-Bar Row',
      description:
          'Set the machine so your upper chest rests at the top of the pad, then grab the handles and let your arms hang extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_T-Bar_Row/0.jpg',
    ),
    Exercise(
      id: 'Mixed_Grip_Chin',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Mixed Grip Chin',
      description:
          'Grab a pull-up bar just wider than shoulder width with one palm facing you and one facing away, hanging with arms fully extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Mixed_Grip_Chin/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Dumbbell_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'One-Arm Dumbbell Row',
      description:
          'With one hand and knee on a bench and a flat back, let the dumbbell hang.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Dumbbell_Row/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Long_Bar_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'One-Arm Long Bar Row',
      description:
          'Wedge a barbell into a landmine and load the working end, then stand beside the bar and grab it just behind the collar with one hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Long_Bar_Row/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Grip_Bent-Over_Rows',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Reverse Grip Bent-Over Rows',
      description:
          'Hinge to near-parallel with an underhand grip and flat back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Grip_Bent-Over_Rows/0.jpg',
    ),
    Exercise(
      id: 'Rope_Climb',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Rope Climb',
      description:
          'Grip the rope overhead with both hands, then pull down hard as you jump and wrap the rope around one leg, pinching it between your feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Climb/0.jpg',
    ),
    Exercise(
      id: 'Rowing_Stationary',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Quadriceps',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Rowing, Stationary',
      description:
          'Sit on the rower, strap in your feet with your heels on the pedals, and slide forward into the catch with knees bent and shins vertical.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rowing_Stationary/0.jpg',
    ),
    Exercise(
      id: 'Seated_Cable_Rows',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Seated Cable Rows',
      description:
          'Sit tall with a slight knee bend and grip the handle.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Cable_Rows/0.jpg',
    ),
    Exercise(
      id: 'Seated_One-arm_Cable_Pulley_Rows',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Seated One-arm Cable Pulley Rows',
      description:
          'Sit at a low cable station with your feet braced and knees slightly bent, then take a single handle in one hand and reach forward so your shoulder stretches.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_One-arm_Cable_Pulley_Rows/0.jpg',
    ),
    Exercise(
      id: 'Shotgun_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Shotgun Row',
      description:
          'Attach a single handle to a low cable and grab it with one hand, then step back into a split stance until the cable is tight, arm extended and shoulder forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Shotgun_Row/0.jpg',
    ),
    Exercise(
      id: 'Side_To_Side_Chins',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Side To Side Chins',
      description:
          'Grab a pull-up bar with a wide overhand grip and hang with arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_To_Side_Chins/0.jpg',
    ),
    Exercise(
      id: 'Sled_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Sled Row',
      description:
          'Attach two handles to a loaded sled and face it, backing up until the rope pulls tight with a handle in each hand and knees slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Row/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Bent_Over_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Smith Machine Bent Over Row',
      description:
          'Hold the bar with an overhand grip, soften the knees and hinge at the hips until the torso is near parallel with a flat back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Bent_Over_Row/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Upright_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Traps', 'Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Smith Machine Upright Row',
      description:
          'Set the Smith bar at mid-thigh height and grip it shoulder width with an overhand grip, then unrack and stand tall with arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Upright_Row/0.jpg',
    ),
    Exercise(
      id: 'Standing_Dumbbell_Upright_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Traps', 'Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Standing Dumbbell Upright Row',
      description:
          'Hold the dumbbells in front of the thighs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Upright_Row/0.jpg',
    ),
    Exercise(
      id: 'Straight_Bar_Bench_Mid_Rows',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Straight Bar Bench Mid Rows',
      description:
          'Place a loaded barbell on the end of a bench and stand on the bench behind it, hinging down to take a medium overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight_Bar_Bench_Mid_Rows/0.jpg',
    ),
    Exercise(
      id: 'Suspended_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Suspended Row',
      description:
          'Set suspension straps at chest height, take a handle in each hand, and lean back with arms extended, body straight from head to heels.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Row/0.jpg',
    ),
    Exercise(
      id: 'T-Bar_Row_with_Handle',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'T-Bar Row with Handle',
      description:
          'Wedge a barbell into a landmine and load the working end, then straddle the bar and loop a double-D handle around it near the collar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/T-Bar_Row_with_Handle/0.jpg',
    ),
    Exercise(
      id: 'Two-Arm_Kettlebell_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: ['Upper back', 'Lats', 'Biceps', 'Forearms', 'Core'],
      name: 'Two-Arm Kettlebell Row',
      description:
          'Set two kettlebells just in front of your feet, then bend your knees slightly and push your hips back to hinge over with a flat back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Row/0.jpg',
    ),
    Exercise(
      id: 'Upright_Barbell_Row',
      category: ExerciseCategory.horizontalPull,
      muscles: [
        'Shoulders',
        'Upper back',
        'Lats',
        'Biceps',
        'Forearms',
        'Core',
      ],
      name: 'Upright Barbell Row',
      description:
          'Grip a barbell with an overhand grip slightly narrower than shoulder width, arms hanging so the bar rests on your thighs and your back straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Upright_Barbell_Row/0.jpg',
    ),
    Exercise(
      id: 'Alternating_Floor_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Alternating Floor Press',
      description:
          'Lie on your back with a kettlebell racked at each shoulder, palms facing forward and elbows on the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Floor_Press/0.jpg',
    ),
    Exercise(
      id: 'Around_The_Worlds',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Around The Worlds',
      description:
          'Lie flat on a bench holding a dumbbell in each hand at your thighs, palms up and elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Around_The_Worlds/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Bench_Press_-_Medium_Grip',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Barbell Bench Press',
      description:
          'Lie on a flat bench and take a grip that puts the forearms vertical at the bottom.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Bench_Press_-_Medium_Grip/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Guillotine_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Barbell Guillotine Bench Press',
      description:
          'Lie on a flat bench and take a medium-wide grip on the bar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Guillotine_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Incline_Bench_Press_-_Medium_Grip',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Barbell Incline Bench Press',
      description:
          'Lie back on an incline bench and grip the bar at medium width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Incline_Bench_Press_-_Medium_Grip/0.jpg',
    ),
    Exercise(
      id: 'Bench_Press_-_Powerlifting',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Bench Press - Powerlifting',
      description:
          'Lie on the bench with your eyes under the bar, plant your feet, and arch your back with shoulder blades squeezed together.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Press_-_Powerlifting/0.jpg',
    ),
    Exercise(
      id: 'Bench_Press_with_Chains',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Bench Press with Chains',
      description:
          'Drape the chains over the bar sleeves and lie on the bench with your eyes under the bar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Press_with_Chains/0.jpg',
    ),
    Exercise(
      id: 'Board_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Board Press',
      description:
          'Have a partner hold a stack of boards on your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Board_Press/0.jpg',
    ),
    Exercise(
      id: 'Cable_Chest_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Cable Chest Press',
      description:
          'Sit at the cable station and grab a handle in each hand with your upper arms about 45 degrees from your body and elbows bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Chest_Press/0.jpg',
    ),
    Exercise(
      id: 'Chain_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Chain Press',
      description:
          'Attach handles to the chains and lie back on a flat bench holding one in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chain_Press/0.jpg',
    ),
    Exercise(
      id: 'Close-Grip_Barbell_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Close-Grip Barbell Bench Press',
      description:
          'Lie back on a flat bench and grip the bar at about shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Barbell_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Cross_Over_-_With_Bands',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Cross Over - With Bands',
      description:
          'Anchor a band to a post and face away, holding a handle in each hand with arms out to your sides at shoulder height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cross_Over_-_With_Bands/0.jpg',
    ),
    Exercise(
      id: 'Decline_Barbell_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Decline Barbell Bench Press',
      description:
          'On a decline bench with feet secured, unrack and hold the bar over the lower chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Barbell_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Decline_Dumbbell_Flyes',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Decline Dumbbell Flyes',
      description:
          'Secure your legs on a decline bench and lie back with a dumbbell in each hand over your chest, palms facing each other and elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Dumbbell_Flyes/0.jpg',
    ),
    Exercise(
      id: 'Decline_Smith_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Decline Smith Press',
      description:
          'Set a decline bench in a Smith machine and lie back so the bar sits over your lower chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Smith_Press/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Bench_Press_with_Neutral_Grip',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Dumbbell Bench Press with Neutral Grip',
      description:
          'Lie flat holding the dumbbells over the chest with palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Bench_Press_with_Neutral_Grip/0.jpg',
    ),
    Exercise(
      id: 'Extended_Range_One-Arm_Kettlebell_Floor_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Extended Range One-Arm Kettlebell Floor Press',
      description:
          'Lie on the floor holding a kettlebell by the handle in one hand at your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Extended_Range_One-Arm_Kettlebell_Floor_Press/0.jpg',
    ),
    Exercise(
      id: 'Floor_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Floor Press',
      description:
          'Lie on the floor under a power rack with the bar set on the j-hooks above your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Floor_Press/0.jpg',
    ),
    Exercise(
      id: 'Floor_Press_with_Chains',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Floor Press with Chains',
      description:
          'Drape the chains over the ends of the bar and lie on the floor under a power rack.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Floor_Press_with_Chains/0.jpg',
    ),
    Exercise(
      id: 'Forward_Drag_with_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Forward Drag with Press',
      description:
          'Attach two rope handles to a sled and face away with a handle at each side of your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Forward_Drag_with_Press/0.jpg',
    ),
    Exercise(
      id: 'Hammer_Grip_Incline_DB_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Hammer Grip Incline DB Bench Press',
      description:
          'Lie back on an incline bench holding a dumbbell in each hand with palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hammer_Grip_Incline_DB_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Incline_Cable_Chest_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Incline Cable Chest Press',
      description:
          'Sit at the cable station and grasp a handle in each hand with elbows bent about 90 degrees and upper arms at 45 degrees to your body.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Cable_Chest_Press/0.jpg',
    ),
    Exercise(
      id: 'Incline_Dumbbell_Bench_With_Palms_Facing_In',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Incline Dumbbell Bench With Palms Facing In',
      description:
          'Lie back on an incline bench with a dumbbell in each hand resting at the sides of your chest, palms facing in toward each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Bench_With_Palms_Facing_In/0.jpg',
    ),
    Exercise(
      id: 'Incline_Dumbbell_Flyes',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Incline Dumbbell Flyes',
      description:
          'On an incline with the dumbbells above the chest and a slight elbow bend, open the arms out to the sides until you feel a chest stretch, then bring them back together in an arc.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Flyes/0.jpg',
    ),
    Exercise(
      id: 'Incline_Dumbbell_Flyes_-_With_A_Twist',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Incline Dumbbell Flyes - With A Twist',
      description:
          'Lie on an incline bench set no higher than 30 degrees, holding a dumbbell in each hand extended above your chest with a slight elbow bend.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Flyes_-_With_A_Twist/0.jpg',
    ),
    Exercise(
      id: 'Incline_Dumbbell_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Incline Dumbbell Press',
      description:
          'On a 30-45 degree incline, start with the dumbbells at the upper chest, palms forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'Isometric_Wipers',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Isometric Wipers',
      description:
          'Set up in a push-up position with your body straight and hands just outside shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Wipers/0.jpg',
    ),
    Exercise(
      id: 'Leg-Over_Floor_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Leg-Over Floor Press',
      description:
          'Lie on the floor holding a kettlebell at your chest by the handle, with your free arm out to the side for support.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg-Over_Floor_Press/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Chest_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Leverage Chest Press',
      description:
          'Adjust the seat so the handles sit at the middle of your chest and grasp them with your chest up and shoulder blades pulled back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Chest_Press/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Decline_Chest_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Leverage Decline Chest Press',
      description:
          'Adjust the seat so the handles line up with the lower edge of your chest and grip them with your chest up and shoulder blades squeezed.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Decline_Chest_Press/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Incline_Chest_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Leverage Incline Chest Press',
      description:
          'Adjust the seat so the handles align with the top of your chest and grasp them with your chest up and shoulder blades pulled back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Incline_Chest_Press/0.jpg',
    ),
    Exercise(
      id: 'Machine_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Machine Bench Press',
      description:
          'Set the seat so the handles line up with the mid-chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Neck_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Neck Press',
      description:
          'Lie on a flat bench and take a medium grip on the bar, then lift it from the rack and hold it above your upper chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Neck_Press/0.jpg',
    ),
    Exercise(
      id: 'One_Arm_Dumbbell_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'One Arm Dumbbell Bench Press',
      description:
          'Lie on a flat bench holding a single dumbbell at shoulder level with one hand, palm facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Dumbbell_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'One_Arm_Floor_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'One Arm Floor Press',
      description:
          'Lie on your back on the floor with your knees bent and take the bar in one hand with your arm extended above your shoulder.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Floor_Press/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Floor_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'One-Arm Kettlebell Floor Press',
      description:
          'Lie on the floor holding a kettlebell in one hand with your upper arm resting on the floor and palm facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Floor_Press/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Band_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Reverse Band Bench Press',
      description:
          'Set a bench in a power rack and loop bands from the top of the rack down to each end of the bar so they help lift at the bottom.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Triceps_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Triceps', 'Chest', 'Shoulders', 'Core'],
      name: 'Reverse Triceps Bench Press',
      description:
          'Lie on a flat bench and take a close, underhand grip about shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Triceps_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Incline_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Smith Machine Incline Bench Press',
      description:
          'Set an incline bench under the Smith machine, with the bar set where your arms are almost fully extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Incline_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Standing_Cable_Chest_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Standing Cable Chest Press',
      description:
          'Set both pulleys to chest height and grab a handle in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Cable_Chest_Press/0.jpg',
    ),
    Exercise(
      id: 'Svend_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Svend Press',
      description:
          'Stand tall and press two light plates flat together at chest height, fingers pointing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Svend_Press/0.jpg',
    ),
    Exercise(
      id: 'Wide-Grip_Barbell_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Wide-Grip Barbell Bench Press',
      description:
          'Lie on a flat bench with feet planted.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Barbell_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Wide-Grip_Decline_Barbell_Bench_Press',
      category: ExerciseCategory.horizontalPush,
      muscles: ['Chest', 'Triceps', 'Shoulders', 'Core'],
      name: 'Wide-Grip Decline Barbell Bench Press',
      description:
          'Lie on a decline bench with your feet locked in at the front.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Decline_Barbell_Bench_Press/0.jpg',
    ),
    Exercise(
      id: 'Bent-Arm_Barbell_Pullover',
      category: ExerciseCategory.other,
      muscles: ['Lats'],
      name: 'Bent-Arm Barbell Pullover',
      description:
          'Lie on a flat bench holding a barbell over your chest with a shoulder-width grip and a bend in your elbows.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent-Arm_Barbell_Pullover/0.jpg',
    ),
    Exercise(
      id: 'Bent-Arm_Dumbbell_Pullover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Bent-Arm Dumbbell Pullover',
      description:
          'Lie across a bench holding one dumbbell over the chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent-Arm_Dumbbell_Pullover/0.jpg',
    ),
    Exercise(
      id: 'Cable_Incline_Pushdown',
      category: ExerciseCategory.other,
      muscles: ['Lats'],
      name: 'Cable Incline Pushdown',
      description:
          'Lie on an incline bench facing away from a high pulley, holding a straight bar overhead with a shoulder-width overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Incline_Pushdown/0.jpg',
    ),
    Exercise(
      id: 'Front_Raise_And_Pullover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Front Raise And Pullover',
      description:
          'Lie on a flat bench holding a barbell over your thighs, palms down and hands about 15 inches apart with a slight elbow bend.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Raise_And_Pullover/0.jpg',
    ),
    Exercise(
      id: 'Incline_Bench_Pull',
      category: ExerciseCategory.other,
      muscles: ['Upper back'],
      name: 'Incline Bench Pull',
      description:
          'Set an incline bench near 30 degrees and lie chest-down on it holding a barbell with an overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Bench_Pull/0.jpg',
    ),
    Exercise(
      id: 'Straight-Arm_Dumbbell_Pullover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Straight-Arm Dumbbell Pullover',
      description:
          'Lie across or along a bench holding one dumbbell over the chest with a slight elbow bend.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight-Arm_Dumbbell_Pullover/0.jpg',
    ),
    Exercise(
      id: 'Wide-Grip_Decline_Barbell_Pullover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Wide-Grip Decline Barbell Pullover',
      description:
          'Lie on a decline bench with your legs locked in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Decline_Barbell_Pullover/0.jpg',
    ),
    Exercise(
      id: 'Alternate_Hammer_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Alternate Hammer Curl',
      description:
          'Stand tall with a dumbbell in each hand at arm\'s length, palms facing your torso and elbows close to your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Hammer_Curl/0.jpg',
    ),
    Exercise(
      id: 'Alternate_Incline_Dumbbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Alternate Incline Dumbbell Curl',
      description:
          'Sit back on an incline bench with a dumbbell in each hand hanging at arm\'s length, palms forward and elbows close to your torso.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Incline_Dumbbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Barbell Curl',
      description:
          'Stand tall holding the bar with an underhand shoulder-width grip and elbows pinned to the sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Curls_Lying_Against_An_Incline',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Barbell Curls Lying Against An Incline',
      description:
          'Lie chest-down against an incline bench holding a barbell with your arms hanging straight down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Curls_Lying_Against_An_Incline/0.jpg',
    ),
    Exercise(
      id: 'Cable_Hammer_Curls_-_Rope_Attachment',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Cable Hammer Curls - Rope Attachment',
      description:
          'Attach a rope to a low pulley and stand facing it with a neutral grip on both ends.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Hammer_Curls_-_Rope_Attachment/0.jpg',
    ),
    Exercise(
      id: 'Cable_Preacher_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Cable Preacher Curl',
      description:
          'With the upper arms flat on the preacher pad, curl the bar or dumbbell up, then lower under control to a near-full extension.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Preacher_Curl/0.jpg',
    ),
    Exercise(
      id: 'Close-Grip_EZ_Bar_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Close-Grip EZ Bar Curl',
      description:
          'Stand tall and grip the EZ bar at the inner handles with palms facing forward and elbows pinned to your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_EZ_Bar_Curl/0.jpg',
    ),
    Exercise(
      id: 'Close-Grip_Standing_Barbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Close-Grip Standing Barbell Curl',
      description:
          'Stand with feet shoulder-width, holding a straight barbell palms-up with your hands a few inches apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Standing_Barbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Concentration_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Concentration Curls',
      description:
          'Seated, brace the working elbow against the inner thigh with the dumbbell hanging.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Concentration_Curls/0.jpg',
    ),
    Exercise(
      id: 'Cross_Body_Hammer_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Cross Body Hammer Curl',
      description:
          'Stand tall with a dumbbell in each hand and palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cross_Body_Hammer_Curl/0.jpg',
    ),
    Exercise(
      id: 'Drag_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Drag Curl',
      description:
          'Hold a barbell with a palms-up grip and elbows drawn back behind your torso.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Drag_Curl/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Alternate_Bicep_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Dumbbell Alternate Bicep Curl',
      description:
          'Stand upright with a dumbbell in each hand, arms at your sides and palms facing your thighs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Alternate_Bicep_Curl/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Prone_Incline_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Dumbbell Prone Incline Curl',
      description:
          'Lie face down on an incline bench with your chest supported and shoulders near the top.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Prone_Incline_Curl/0.jpg',
    ),
    Exercise(
      id: 'EZ-Bar_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'EZ-Bar Curl',
      description:
          'Stand tall holding an EZ bar at the wide outer handles with palms facing forward and elbows close to your torso.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/EZ-Bar_Curl/0.jpg',
    ),
    Exercise(
      id: 'Flexor_Incline_Dumbbell_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Flexor Incline Dumbbell Curls',
      description:
          'Sit back on an incline bench with a dumbbell in each hand, gripping toward the far end so the near side is heavier.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flexor_Incline_Dumbbell_Curls/0.jpg',
    ),
    Exercise(
      id: 'Hammer_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Hammer Curls',
      description:
          'Stand holding the dumbbells with a neutral (palms-in) grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hammer_Curls/0.jpg',
    ),
    Exercise(
      id: 'High_Cable_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'High Cable Curls',
      description:
          'Stand between two high pulleys and grab a handle in each hand with your upper arms raised parallel to the floor and palms facing you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/High_Cable_Curls/0.jpg',
    ),
    Exercise(
      id: 'Incline_Hammer_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Incline Hammer Curls',
      description:
          'Sit back against an incline bench with a dumbbell in each hand hanging straight down and palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Hammer_Curls/0.jpg',
    ),
    Exercise(
      id: 'Incline_Inner_Biceps_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Incline Inner Biceps Curl',
      description:
          'Lie back on an incline bench with a dumbbell in each hand at arm\'s length and palms facing outward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Inner_Biceps_Curl/0.jpg',
    ),
    Exercise(
      id: 'Lying_Cable_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Lying Cable Curl',
      description:
          'Attach a bar to a low pulley and lie on your back on the floor facing the stack.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Cable_Curl/0.jpg',
    ),
    Exercise(
      id: 'Lying_Close-Grip_Bar_Curl_On_High_Pulley',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Lying Close-Grip Bar Curl On High Pulley',
      description:
          'Set a flat bench in front of a high pulley and grab the straight bar underhand at shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Close-Grip_Bar_Curl_On_High_Pulley/0.jpg',
    ),
    Exercise(
      id: 'Lying_High_Bench_Barbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Lying High Bench Barbell Curl',
      description:
          'Lie face down on a tall flat bench holding a barbell with a palms-up, shoulder-width grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_High_Bench_Barbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Lying_Supine_Dumbbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Lying Supine Dumbbell Curl',
      description:
          'Lie face up on a flat bench with a dumbbell in each hand and your arms hanging down toward the floor at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Supine_Dumbbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Machine_Preacher_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Machine Preacher Curls',
      description:
          'Sit at the machine and rest the back of your upper arms flat on the pad.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Preacher_Curls/0.jpg',
    ),
    Exercise(
      id: 'One_Arm_Dumbbell_Preacher_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'One Arm Dumbbell Preacher Curl',
      description:
          'Rest the back of one upper arm on a preacher bench and hold a dumbbell with an underhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Dumbbell_Preacher_Curl/0.jpg',
    ),
    Exercise(
      id: 'Overhead_Cable_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Overhead Cable Curl',
      description:
          'Set both pulleys high and grab a handle in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Overhead_Cable_Curl/0.jpg',
    ),
    Exercise(
      id: 'Preacher_Hammer_Dumbbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Preacher Hammer Dumbbell Curl',
      description:
          'Rest both upper arms on a preacher bench and hold a dumbbell in each hand with palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Preacher_Hammer_Dumbbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Barbell_Preacher_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Reverse Barbell Preacher Curls',
      description:
          'Grip an EZ-bar at shoulder width with your palms facing down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Barbell_Preacher_Curls/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Cable_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Reverse Cable Curl',
      description:
          'Attach a straight bar to a low pulley and grip it at shoulder width with palms facing down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Cable_Curl/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Plate_Curls',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Reverse Plate Curls',
      description:
          'Stand tall holding a weight plate in both hands with your arms hanging straight and palms facing down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Plate_Curls/0.jpg',
    ),
    Exercise(
      id: 'Seated_Close-Grip_Concentration_Barbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Seated Close-Grip Concentration Barbell Curl',
      description:
          'Sit on a flat bench with your legs spread and hold a barbell with a close, underhand grip between your knees.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Close-Grip_Concentration_Barbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Seated_Dumbbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Seated Dumbbell Curl',
      description:
          'Sit on a flat bench holding a dumbbell in each hand at arm\'s length with elbows close to your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Seated_Dumbbell_Inner_Biceps_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Seated Dumbbell Inner Biceps Curl',
      description:
          'Sit on the end of a flat bench holding a dumbbell in each hand at arm\'s length, elbows close and palms facing inward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Inner_Biceps_Curl/0.jpg',
    ),
    Exercise(
      id: 'Spider_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Spider Curl',
      description:
          'Lean your chest against the steep side of a preacher bench and let your arms hang straight down holding an EZ-bar underhand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Spider_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Biceps_Cable_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Standing Biceps Cable Curl',
      description:
          'Stand tall holding a cable curl bar on a low pulley with a shoulder-width, palms-up grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Biceps_Cable_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Concentration_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Standing Concentration Curl',
      description:
          'Hold a dumbbell in your working hand and lean forward at the hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Concentration_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Dumbbell_Reverse_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Standing Dumbbell Reverse Curl',
      description:
          'Stand tall with a dumbbell in each hand and your palms facing down, arms fully extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Reverse_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Inner-Biceps_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Standing Inner-Biceps Curl',
      description:
          'Stand with a dumbbell in each hand at arm\'s length, elbows close to your sides and palms facing inward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Inner-Biceps_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_One-Arm_Cable_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Standing One-Arm Cable Curl',
      description:
          'Grab a single handle at the low pulley and step back so the cable stays taut.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_One-Arm_Cable_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_One-Arm_Dumbbell_Curl_Over_Incline_Bench',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Standing One-Arm Dumbbell Curl Over Incline Bench',
      description:
          'Stand behind an incline bench and drape your working arm over the top of the pad, palm up, dumbbell hanging.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_One-Arm_Dumbbell_Curl_Over_Incline_Bench/0.jpg',
    ),
    Exercise(
      id: 'Two-Arm_Dumbbell_Preacher_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Two-Arm Dumbbell Preacher Curl',
      description:
          'Sit at a preacher bench and set both upper arms flat on the pad, a dumbbell in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Dumbbell_Preacher_Curl/0.jpg',
    ),
    Exercise(
      id: 'Wide-Grip_Standing_Barbell_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Wide-Grip Standing Barbell Curl',
      description:
          'Stand tall holding a barbell with a wide grip, palms forward and elbows tucked to your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Standing_Barbell_Curl/0.jpg',
    ),
    Exercise(
      id: 'Zottman_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Zottman Curl',
      description:
          'Stand tall with a dumbbell in each hand, palms facing in and elbows tucked.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Zottman_Curl/0.jpg',
    ),
    Exercise(
      id: 'Zottman_Preacher_Curl',
      category: ExerciseCategory.other,
      muscles: ['Biceps'],
      name: 'Zottman Preacher Curl',
      description:
          'Rest your upper arms on the preacher pad holding a dumbbell in each hand at the top with palms facing down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Zottman_Preacher_Curl/0.jpg',
    ),
    Exercise(
      id: 'Balance_Board',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Balance Board',
      description:
          'Set a balance board on the floor and step onto it with both feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Balance_Board/0.jpg',
    ),
    Exercise(
      id: 'Calf_Press',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Calf Press',
      description:
          'Set the balls of your feet on the platform with heels hanging off and legs only slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Press/0.jpg',
    ),
    Exercise(
      id: 'Calf_Raise_On_A_Dumbbell',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Calf Raise On A Dumbbell',
      description:
          'Hold a sturdy object for balance and place the balls of both feet on a dumbbell handle, heels on the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Raise_On_A_Dumbbell/0.jpg',
    ),
    Exercise(
      id: 'Calf_Raises_-_With_Bands',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Calf Raises - With Bands',
      description:
          'Stand on the middle of an exercise band with the balls of both feet, splitting the length evenly.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Raises_-_With_Bands/0.jpg',
    ),
    Exercise(
      id: 'Donkey_Calf_Raises',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Donkey Calf Raises',
      description:
          'Set the balls of your feet on the platform and bend forward at the hips, resting the pad across your lower back and hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Donkey_Calf_Raises/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Seated_One-Leg_Calf_Raise',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Dumbbell Seated One-Leg Calf Raise',
      description:
          'Sit on a bench and rest a dumbbell on your thigh just above the knee.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Seated_One-Leg_Calf_Raise/0.jpg',
    ),
    Exercise(
      id: 'Rocking_Standing_Calf_Raise',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Rocking Standing Calf Raise',
      description:
          'Set a loaded barbell across your upper back inside a squat rack and step out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rocking_Standing_Calf_Raise/0.jpg',
    ),
    Exercise(
      id: 'Seated_Calf_Raise',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Seated Calf Raise',
      description:
          'Sit with the pad on the lower thighs and the balls of the feet on the block.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Calf_Raise/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Reverse_Calf_Raises',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Smith Machine Reverse Calf Raises',
      description:
          'Rest the Smith bar across your upper back and stand on a platform with your heels on it and the balls of your feet off the front edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Reverse_Calf_Raises/0.jpg',
    ),
    Exercise(
      id: 'Standing_Barbell_Calf_Raise',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Standing Barbell Calf Raise',
      description:
          'Set a loaded barbell across your upper back and place the balls of your feet on a block or plate with heels hanging off.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Barbell_Calf_Raise/0.jpg',
    ),
    Exercise(
      id: 'Standing_Calf_Raises',
      category: ExerciseCategory.other,
      muscles: ['Calves'],
      name: 'Standing Calf Raises',
      description:
          'Set the shoulder pads to your height and stand with the balls of your feet on the platform edge, toes forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Calf_Raises/0.jpg',
    ),
    Exercise(
      id: 'Bodyweight_Flyes',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Bodyweight Flyes',
      description:
          'Set two loaded EZ bars parallel on the floor and take a push-up position with a hand on each bar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Flyes/0.jpg',
    ),
    Exercise(
      id: 'Butterfly',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Butterfly',
      description:
          'Sit with your back flat against the pad and grip the handles with your upper arms parallel to the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Butterfly/0.jpg',
    ),
    Exercise(
      id: 'Cable_Crossover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Cable Crossover',
      description:
          'Set the pulleys high, take a handle in each hand and stagger your stance with a slight forward lean.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Crossover/0.jpg',
    ),
    Exercise(
      id: 'Cable_Iron_Cross',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Cable Iron Cross',
      description:
          'Set both pulleys high and take a handle in each hand, standing between them with your arms out to the sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Iron_Cross/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Flyes',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Dumbbell Flyes',
      description:
          'Lie flat on a bench holding a dumbbell in each hand over your chest, palms facing and elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Flyes/0.jpg',
    ),
    Exercise(
      id: 'Flat_Bench_Cable_Flyes',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Flat Bench Cable Flyes',
      description:
          'Set a flat bench between two low pulleys and lie back with a handle in each hand, arms out to your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Cable_Flyes/0.jpg',
    ),
    Exercise(
      id: 'Incline_Cable_Flye',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Incline Cable Flye',
      description:
          'Set both pulleys at floor level and place a 45-degree incline bench between them.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Cable_Flye/0.jpg',
    ),
    Exercise(
      id: 'Low_Cable_Crossover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Low Cable Crossover',
      description:
          'Set both pulleys low and grab a handle in each hand with palms facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Low_Cable_Crossover/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Flat_Bench_Dumbbell_Flye',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'One-Arm Flat Bench Dumbbell Flye',
      description:
          'Lie flat on a bench holding one dumbbell over your chest with a neutral grip and a slight elbow bend.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Flat_Bench_Dumbbell_Flye/0.jpg',
    ),
    Exercise(
      id: 'Single-Arm_Cable_Crossover',
      category: ExerciseCategory.other,
      muscles: ['Chest'],
      name: 'Single-Arm Cable Crossover',
      description:
          'Set the pulley high and take the handle in one hand, stepping forward so the arm is extended out and back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Arm_Cable_Crossover/0.jpg',
    ),
    Exercise(
      id: 'Cable_Wrist_Curl',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Cable Wrist Curl',
      description:
          'Kneel or sit at a flat bench in front of a low pulley with a straight bar, gripping it palms-up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Wrist_Curl/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Lying_Pronation',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Dumbbell Lying Pronation',
      description:
          'Lie face down on a flat bench with one arm hanging off the side, elbow bent to 90 degrees and a dumbbell in that hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_Pronation/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Lying_Supination',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Dumbbell Lying Supination',
      description:
          'Lie on your side on a flat bench with your top arm bent to 90 degrees, holding a dumbbell with the palm facing down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_Supination/0.jpg',
    ),
    Exercise(
      id: 'Finger_Curls',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Finger Curls',
      description:
          'Hold a barbell with a shoulder-width, palms-up grip and let your arms hang at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Finger_Curls/0.jpg',
    ),
    Exercise(
      id: 'Palms-Down_Wrist_Curl_Over_A_Bench',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Palms-Down Wrist Curl Over A Bench',
      description:
          'Kneel at a flat bench and rest your forearms flat on it, gripping a barbell palms-down with your wrists just past the edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Palms-Down_Wrist_Curl_Over_A_Bench/0.jpg',
    ),
    Exercise(
      id: 'Plate_Pinch',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Plate Pinch',
      description:
          'Put two wide-rimmed plates together with the smooth sides facing out, then pinch them between your fingers and thumb.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plate_Pinch/0.jpg',
    ),
    Exercise(
      id: 'Seated_Dumbbell_Palms-Up_Wrist_Curl',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Seated Dumbbell Palms-Up Wrist Curl',
      description:
          'Sit on a flat bench holding a dumbbell in each hand with your palms facing up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Palms-Up_Wrist_Curl/0.jpg',
    ),
    Exercise(
      id: 'Seated_One-Arm_Dumbbell_Palms-Up_Wrist_Curl',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Seated One-Arm Dumbbell Palms-Up Wrist Curl',
      description:
          'Sit on a flat bench with a dumbbell in your right hand, palm up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_One-Arm_Dumbbell_Palms-Up_Wrist_Curl/0.jpg',
    ),
    Exercise(
      id: 'Seated_Palm-Up_Barbell_Wrist_Curl',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Seated Palm-Up Barbell Wrist Curl',
      description:
          'Sit on a flat bench and hold a barbell with an underhand, shoulder-width grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Palm-Up_Barbell_Wrist_Curl/0.jpg',
    ),
    Exercise(
      id: 'Seated_Two-Arm_Palms-Up_Low-Pulley_Wrist_Curl',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Seated Two-Arm Palms-Up Low-Pulley Wrist Curl',
      description:
          'Set a bench in front of a low pulley fitted with a straight bar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Two-Arm_Palms-Up_Low-Pulley_Wrist_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Olympic_Plate_Hand_Squeeze',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Standing Olympic Plate Hand Squeeze',
      description:
          'Stand tall holding a weight plate by its ridge in each hand, arms at your sides with palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Olympic_Plate_Hand_Squeeze/0.jpg',
    ),
    Exercise(
      id: 'Standing_Palms-Up_Barbell_Behind_The_Back_Wrist_Curl',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Standing Palms-Up Barbell Behind The Back Wrist Curl',
      description:
          'Stand upright and hold a barbell behind your glutes at arm\'s length, hands shoulder-width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Palms-Up_Barbell_Behind_The_Back_Wrist_Curl/0.jpg',
    ),
    Exercise(
      id: 'Wrist_Roller',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Wrist Roller',
      description:
          'Stand tall gripping a loaded wrist roller with both hands, palms down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wrist_Roller/0.jpg',
    ),
    Exercise(
      id: 'Wrist_Rotations_with_Straight_Bar',
      category: ExerciseCategory.other,
      muscles: ['Forearms'],
      name: 'Wrist Rotations with Straight Bar',
      description:
          'Hold a barbell with both hands, palms facing down and hands shoulder-width apart, out in front of your thighs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wrist_Rotations_with_Straight_Bar/0.jpg',
    ),
    Exercise(
      id: 'Band_Hip_Adductions',
      category: ExerciseCategory.other,
      muscles: ['Adductors'],
      name: 'Band Hip Adductions',
      description:
          'Anchor a band to a low post and loop it around the ankle of the leg nearest the post.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Hip_Adductions/0.jpg',
    ),
    Exercise(
      id: 'Butt_Lift_Bridge',
      category: ExerciseCategory.other,
      muscles: ['Glutes'],
      name: 'Butt Lift (Bridge)',
      description:
          'Lie on your back with your knees bent and feet flat about shoulder-width apart, arms resting at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Butt_Lift_Bridge/0.jpg',
    ),
    Exercise(
      id: 'Downward_Facing_Balance',
      category: ExerciseCategory.other,
      muscles: ['Glutes'],
      name: 'Downward Facing Balance',
      description:
          'Lie facedown over an exercise ball and walk your hands forward along the floor until the ball sits under your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Downward_Facing_Balance/0.jpg',
    ),
    Exercise(
      id: 'Glute_Kickback',
      category: ExerciseCategory.other,
      muscles: ['Glutes'],
      name: 'Glute Kickback',
      description:
          'Get on your hands and knees with your arms under your shoulders and your back flat.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Glute_Kickback/0.jpg',
    ),
    Exercise(
      id: 'Leg_Lift',
      category: ExerciseCategory.other,
      muscles: ['Glutes'],
      name: 'Leg Lift',
      description:
          'Stand tall beside a squat rack or chair and hold on for balance, feet close together.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Lift/0.jpg',
    ),
    Exercise(
      id: 'Monster_Walk',
      category: ExerciseCategory.other,
      muscles: ['Abductors'],
      name: 'Monster Walk',
      description:
          'Loop one band around your ankles and another around your knees, then set your feet shoulder-width so both bands pull taut.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Monster_Walk/0.jpg',
    ),
    Exercise(
      id: 'One-Legged_Cable_Kickback',
      category: ExerciseCategory.other,
      muscles: ['Glutes'],
      name: 'One-Legged Cable Kickback',
      description:
          'Strap a low cable cuff to your ankle and face the stack, holding the frame for support.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Legged_Cable_Kickback/0.jpg',
    ),
    Exercise(
      id: 'Thigh_Abductor',
      category: ExerciseCategory.other,
      muscles: ['Abductors'],
      name: 'Thigh Abductor',
      description:
          'Sit on the abductor machine with the pads against your outer thighs and grip the handles.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Thigh_Abductor/0.jpg',
    ),
    Exercise(
      id: 'Thigh_Adductor',
      category: ExerciseCategory.other,
      muscles: ['Adductors'],
      name: 'Thigh Adductor',
      description:
          'Sit on the inner thighs machine with the pads against your inner thighs and your legs spread apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Thigh_Adductor/0.jpg',
    ),
    Exercise(
      id: 'Tricep_Dumbbell_Kickback',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Tricep Dumbbell Kickback',
      description:
          'Hold a dumbbell in each hand and hinge forward at the waist until your torso is near parallel to the floor, back flat.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tricep_Dumbbell_Kickback/0.jpg',
    ),
    Exercise(
      id: 'Ball_Leg_Curl',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Ball Leg Curl',
      description:
          'Lie on your back with your heels on top of an exercise ball and legs extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ball_Leg_Curl/0.jpg',
    ),
    Exercise(
      id: 'Floor_Glute-Ham_Raise',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Floor Glute-Ham Raise',
      description:
          'Kneel upright with your feet anchored under something stable and your body straight from knees to head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Floor_Glute-Ham_Raise/0.jpg',
    ),
    Exercise(
      id: 'Lying_Leg_Curls',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Lying Leg Curls',
      description:
          'Lie face down with the pad on the lower calves.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Leg_Curls/0.jpg',
    ),
    Exercise(
      id: 'Platform_Hamstring_Slides',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Platform Hamstring Slides',
      description:
          'Lie on your back with legs extended and a towel or slider under one heel on a smooth floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Platform_Hamstring_Slides/0.jpg',
    ),
    Exercise(
      id: 'Prone_Manual_Hamstring',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Prone Manual Hamstring',
      description:
          'Lie face down with your legs straight and a partner\'s hand pressed against your heel.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Prone_Manual_Hamstring/0.jpg',
    ),
    Exercise(
      id: 'Seated_Band_Hamstring_Curl',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Seated Band Hamstring Curl',
      description:
          'Anchor a band low and sit on a bench placed a couple of feet away.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Band_Hamstring_Curl/0.jpg',
    ),
    Exercise(
      id: 'Seated_Leg_Curl',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Seated Leg Curl',
      description:
          'Sit with the pad on the lower calves and thighs secured.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Leg_Curl/0.jpg',
    ),
    Exercise(
      id: 'Standing_Leg_Curl',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings'],
      name: 'Standing Leg Curl',
      description:
          'Stand at the leg curl machine and hook one ankle behind the padded lever, keeping a slight bend in the working knee.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Leg_Curl/0.jpg',
    ),
    Exercise(
      id: 'Isometric_Neck_Exercise_-_Front_And_Back',
      category: ExerciseCategory.other,
      muscles: ['Neck'],
      name: 'Isometric Neck Exercise - Front And Back',
      description:
          'Sit or stand with your head in a neutral position and place both hands on your forehead.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Neck_Exercise_-_Front_And_Back/0.jpg',
    ),
    Exercise(
      id: 'Isometric_Neck_Exercise_-_Sides',
      category: ExerciseCategory.other,
      muscles: ['Neck'],
      name: 'Isometric Neck Exercise - Sides',
      description:
          'Hold your head in a neutral position and place your left hand against the left side of your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Neck_Exercise_-_Sides/0.jpg',
    ),
    Exercise(
      id: 'Lying_Face_Up_Plate_Neck_Resistance',
      category: ExerciseCategory.other,
      muscles: ['Neck'],
      name: 'Lying Face Up Plate Neck Resistance',
      description:
          'Lie face up on a flat bench with your shoulders just past the end so your head hangs free.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Face_Up_Plate_Neck_Resistance/0.jpg',
    ),
    Exercise(
      id: 'Seated_Head_Harness_Neck_Resistance',
      category: ExerciseCategory.other,
      muscles: ['Neck'],
      name: 'Seated Head Harness Neck Resistance',
      description:
          'Fit a loaded head harness and sit at the end of a flat bench with your feet wider than shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Head_Harness_Neck_Resistance/0.jpg',
    ),
    Exercise(
      id: 'Cable_Hip_Adduction',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps'],
      name: 'Cable Hip Adduction',
      description:
          'Attach an ankle cuff to a low pulley and fix it to the leg nearest the stack.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Hip_Adduction/0.jpg',
    ),
    Exercise(
      id: 'Leg_Extensions',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps'],
      name: 'Leg Extensions',
      description:
          'Sit with the pad on the lower shins and knees at the seat\'s pivot.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Extensions/0.jpg',
    ),
    Exercise(
      id: 'Single-Leg_Leg_Extension',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps'],
      name: 'Single-Leg Leg Extension',
      description:
          'Sit in the machine with the pad against your lower shin just above the ankle and your knee lined up with the pivot.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Leg_Extension/0.jpg',
    ),
    Exercise(
      id: 'Alternating_Deltoid_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Alternating Deltoid Raise',
      description:
          'Stand holding a dumbbell in each hand with elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Deltoid_Raise/0.jpg',
    ),
    Exercise(
      id: 'Back_Flyes_-_With_Bands',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Back Flyes - With Bands',
      description:
          'Anchor a band around a squat rack post at chest height and hold a handle in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Back_Flyes_-_With_Bands/0.jpg',
    ),
    Exercise(
      id: 'Band_Pull_Apart',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Band Pull Apart',
      description:
          'Hold a band with both hands, arms extended straight out in front at shoulder height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Pull_Apart/0.jpg',
    ),
    Exercise(
      id: 'Battling_Ropes',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Battling Ropes',
      description:
          'Anchor a heavy rope at its center and hold one end in each hand with arms at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Battling_Ropes/0.jpg',
    ),
    Exercise(
      id: 'Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Bent Over Dumbbell Rear Delt Raise With Head On Bench',
      description:
          'Set an incline bench and stand holding a dumbbell in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench/0.jpg',
    ),
    Exercise(
      id: 'Bent_Over_Low-Pulley_Side_Lateral',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Bent Over Low-Pulley Side Lateral',
      description:
          'Grab a low pulley handle with one hand and hinge at the waist until your torso is near parallel to the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Low-Pulley_Side_Lateral/0.jpg',
    ),
    Exercise(
      id: 'Cable_Internal_Rotation',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Cable Internal Rotation',
      description:
          'Sit or stand side-on to a low pulley and grab the handle with the arm closest to the machine.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Internal_Rotation/0.jpg',
    ),
    Exercise(
      id: 'Cable_Rear_Delt_Fly',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Cable Rear Delt Fly',
      description:
          'Set both pulleys above head height and grab the left handle with your right hand and the right handle with your left so the cables cross in front.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Rear_Delt_Fly/0.jpg',
    ),
    Exercise(
      id: 'Cable_Seated_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Cable Seated Lateral Raise',
      description:
          'Place a flat bench between two opposing low pulleys and sit on it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Seated_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'Car_Drivers',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Car Drivers',
      description:
          'Stand tall holding a weight plate at the 3 and 9 o\'clock positions, palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Car_Drivers/0.jpg',
    ),
    Exercise(
      id: 'Circus_Bell',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Circus Bell',
      description:
          'Stand over the circus bell with it between your feet and grip the thick handle with both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Circus_Bell/0.jpg',
    ),
    Exercise(
      id: 'Crucifix',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Crucifix',
      description:
          'Hold a weight in each hand and raise both arms straight out to your sides until they are level with your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crucifix/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Lying_One-Arm_Rear_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Dumbbell Lying One-Arm Rear Lateral Raise',
      description:
          'Set a bench to a low incline and lie chest-down on it holding a dumbbell in one hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_One-Arm_Rear_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Lying_Rear_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Dumbbell Lying Rear Lateral Raise',
      description:
          'Lie chest-down on a low-incline bench holding a dumbbell in each hand with palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_Rear_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Dumbbell Raise',
      description:
          'Stand tall holding a dumbbell in each hand at your sides, palms facing your thighs, elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Raise/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Scaption',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Dumbbell Scaption',
      description:
          'Stand holding a light dumbbell in each hand at your sides with thumbs pointing up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Scaption/0.jpg',
    ),
    Exercise(
      id: 'External_Rotation',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'External Rotation',
      description:
          'Lie on your side on a bench holding a dumbbell in the top hand, elbow tucked to your ribs and bent 90 degrees so the weight rests near your belly.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/External_Rotation/0.jpg',
    ),
    Exercise(
      id: 'Front_Cable_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Front Cable Raise',
      description:
          'Face away from a low pulley gripping the single handle with one hand, arm hanging straight in front of your thigh.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Cable_Raise/0.jpg',
    ),
    Exercise(
      id: 'Front_Incline_Dumbbell_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Front Incline Dumbbell Raise',
      description:
          'Sit against an incline bench set to 30 to 60 degrees, holding a dumbbell in each hand with arms straight down and palms facing back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Incline_Dumbbell_Raise/0.jpg',
    ),
    Exercise(
      id: 'Front_Plate_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Front Plate Raise',
      description:
          'Stand tall gripping a weight plate at the 3 and 9 o\'clock edges, palms facing each other, arms extended down with a slight elbow bend.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Plate_Raise/0.jpg',
    ),
    Exercise(
      id: 'Front_Two-Dumbbell_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Front Two-Dumbbell Raise',
      description:
          'Stand with a straight torso holding a dumbbell in each hand in front of your thighs, palms facing you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Two-Dumbbell_Raise/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Pirate_Ships',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Kettlebell Pirate Ships',
      description:
          'Take a wide stance and hold one kettlebell with both hands, arms hanging at waist level.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Pirate_Ships/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Thruster',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Kettlebell Thruster',
      description:
          'Hold two kettlebells racked at your shoulders, feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Thruster/0.jpg',
    ),
    Exercise(
      id: 'Landmine_Linear_Jammer',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Landmine Linear Jammer',
      description:
          'Anchor a landmine bar and hold the handles at your shoulders in an athletic, even stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Landmine_Linear_Jammer/0.jpg',
    ),
    Exercise(
      id: 'Lateral_Raise_-_With_Bands',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Lateral Raise - With Bands',
      description:
          'Stand on an exercise band with a handle in each hand, palms facing your thighs, hands just inside shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Raise_-_With_Bands/0.jpg',
    ),
    Exercise(
      id: 'Log_Lift',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Log Lift',
      description:
          'Stand over the log and grip the handles, hips back and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Log_Lift/0.jpg',
    ),
    Exercise(
      id: 'Lying_One-Arm_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Lying One-Arm Lateral Raise',
      description:
          'Lie chest-down on a flat bench holding a dumbbell in one hand, palm neutral, arm hanging toward the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_One-Arm_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'Lying_Rear_Delt_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Lying Rear Delt Raise',
      description:
          'Lie chest-down on a flat bench holding a dumbbell in each hand, palms facing your torso and elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Rear_Delt_Raise/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Incline_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'One-Arm Incline Lateral Raise',
      description:
          'Lie on your side on an incline bench with your lower shoulder against the pad, holding a dumbbell in your top hand across your body near your navel.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Incline_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Side_Laterals',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'One-Arm Side Laterals',
      description:
          'Hold a dumbbell in one hand and grip a steady upright like an incline bench with your other hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Side_Laterals/0.jpg',
    ),
    Exercise(
      id: 'Power_Partials',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Power Partials',
      description:
          'Stand tall with a dumbbell in each hand at arms length, palms facing your body and elbows close to your torso.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Partials/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Flyes',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Reverse Flyes',
      description:
          'Lie chest-down on an incline bench holding a dumbbell in each hand with a neutral grip, arms hanging with a slight elbow bend.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Flyes/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Flyes_With_External_Rotation',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Reverse Flyes With External Rotation',
      description:
          'Lie chest-down on an incline bench set to 30 degrees with a dumbbell in each hand hanging below you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Flyes_With_External_Rotation/0.jpg',
    ),
    Exercise(
      id: 'Seated_Bent-Over_Rear_Delt_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Seated Bent-Over Rear Delt Raise',
      description:
          'Sit on the end of a flat bench with your feet together and a dumbbell beside each calf.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Bent-Over_Rear_Delt_Raise/0.jpg',
    ),
    Exercise(
      id: 'Seated_Side_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Seated Side Lateral Raise',
      description:
          'Seated with dumbbells at the sides and a slight elbow bend, raise the arms out to about shoulder height leading with the elbows, then lower under control.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Side_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'Side_Lateral_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Side Lateral Raise',
      description:
          'Stand tall with a dumbbell in each hand by your sides, palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Lateral_Raise/0.jpg',
    ),
    Exercise(
      id: 'Side_Laterals_to_Front_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Side Laterals to Front Raise',
      description:
          'Stand holding a dumbbell in each hand with your elbows slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Laterals_to_Front_Raise/0.jpg',
    ),
    Exercise(
      id: 'Single_Dumbbell_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Single Dumbbell Raise',
      description:
          'Take a wide stance and hold one dumbbell with both hands, cupping the top head of the bell.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Dumbbell_Raise/0.jpg',
    ),
    Exercise(
      id: 'Single-Arm_Linear_Jammer',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Single-Arm Linear Jammer',
      description:
          'Anchor a barbell in a landmine and bring the loaded end up to one shoulder, taking a wide stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Arm_Linear_Jammer/0.jpg',
    ),
    Exercise(
      id: 'Sled_Reverse_Flye',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Sled Reverse Flye',
      description:
          'Attach two handles to a sled and face it, backing up until the line has tension.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Reverse_Flye/0.jpg',
    ),
    Exercise(
      id: 'Smith_Incline_Shoulder_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Smith Incline Shoulder Raise',
      description:
          'Set an incline bench under a Smith machine and lie back with the bar at nearly full arm extension.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Incline_Shoulder_Raise/0.jpg',
    ),
    Exercise(
      id: 'Standing_Dumbbell_Straight-Arm_Front_Delt_Raise_Above_Head',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Standing Dumbbell Straight-Arm Front Delt Raise Above Head',
      description:
          'Stand holding a dumbbell in front of each thigh, palms facing in and arms straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Straight-Arm_Front_Delt_Raise_Above_Head/0.jpg',
    ),
    Exercise(
      id: 'Standing_Front_Barbell_Raise_Over_Head',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Standing Front Barbell Raise Over Head',
      description:
          'Stand tall holding a barbell against your thighs with an overhand grip slightly narrower than shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Front_Barbell_Raise_Over_Head/0.jpg',
    ),
    Exercise(
      id: 'Standing_Low-Pulley_Deltoid_Raise',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Standing Low-Pulley Deltoid Raise',
      description:
          'Stand to one side of a low pulley and grip the single handle with an overhand grip, letting that arm rest across the front of your body.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Low-Pulley_Deltoid_Raise/0.jpg',
    ),
    Exercise(
      id: 'Straight_Raises_on_Incline_Bench',
      category: ExerciseCategory.other,
      muscles: ['Shoulders'],
      name: 'Straight Raises on Incline Bench',
      description:
          'Lie face down on an incline bench and grip a barbell on the floor with an overhand grip, arms straight and hanging below you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight_Raises_on_Incline_Bench/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Barbell Shrug',
      description:
          'Hold the bar in front of the thighs with straight arms.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Cable_Shrugs',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Cable Shrugs',
      description:
          'Grip a bar attached to a low pulley with an overhand, shoulder-width grip and stand tall close to the machine.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Shrugs/0.jpg',
    ),
    Exercise(
      id: 'Calf-Machine_Shoulder_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Calf-Machine Shoulder Shrug',
      description:
          'Step onto the calf machine and settle the shoulder pads on top of your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf-Machine_Shoulder_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Clean_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Clean Shrug',
      description:
          'Hold a barbell at mid-thigh with a shoulder-width overhand or hook grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Leverage Shrug',
      description:
          'Load the machine and stand directly between the handles.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Middle_Back_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Upper back'],
      name: 'Middle Back Shrug',
      description:
          'Lie chest-down on an incline bench with a dumbbell in each hand, arms hanging straight down and palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Middle_Back_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Behind_the_Back_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Smith Machine Behind the Back Shrug',
      description:
          'Set the Smith bar at thigh height and stand in front of it so the bar rests behind your legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Behind_the_Back_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Snatch_Shrug',
      category: ExerciseCategory.other,
      muscles: ['Traps'],
      name: 'Snatch Shrug',
      description:
          'Hold a barbell at mid-thigh with a wide snatch-width overhand or hook grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Shrug/0.jpg',
    ),
    Exercise(
      id: 'Band_Skull_Crusher',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Band Skull Crusher',
      description:
          'Anchor a band low behind a bench and lie down with the band running past your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Skull_Crusher/0.jpg',
    ),
    Exercise(
      id: 'Bench_Dips',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Bench Dips',
      description:
          'Sit on the edge of a bench and grip the edge beside your hips, then walk your feet out and lift your hips off.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Dips/0.jpg',
    ),
    Exercise(
      id: 'Body_Tricep_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Body Tricep Press',
      description:
          'Set a bar in a rack at chest height and take a shoulder-width grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Body_Tricep_Press/0.jpg',
    ),
    Exercise(
      id: 'Body-Up',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Body-Up',
      description:
          'Start in a forearm plank on your toes with a straight torso and forearms shoulder-width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Body-Up/0.jpg',
    ),
    Exercise(
      id: 'Cable_Lying_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Cable Lying Triceps Extension',
      description:
          'Lie on a flat bench at the end of a low pulley and hold the straight bar with a narrow overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Lying_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Cable_One_Arm_Tricep_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Cable One Arm Tricep Extension',
      description:
          'Stand facing a high pulley and hold the single handle in one hand with an underhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_One_Arm_Tricep_Extension/0.jpg',
    ),
    Exercise(
      id: 'Cable_Rope_Overhead_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Cable Rope Overhead Triceps Extension',
      description:
          'Facing away from the pulley with the rope overhead and elbows by the ears, extend the arms forward and up, then return to a stretch behind the head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Rope_Overhead_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Chain_Handle_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Chain Handle Extension',
      description:
          'Clip chains to two cable handles and lie back on a flat bench holding one in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chain_Handle_Extension/0.jpg',
    ),
    Exercise(
      id: 'Close-Grip_Dumbbell_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Close-Grip Dumbbell Press',
      description:
          'Stand a dumbbell upright on a flat bench, then lie perpendicular across it so only your shoulders are supported with your hips dropped below.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'Close-Grip_EZ-Bar_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Close-Grip EZ-Bar Press',
      description:
          'Lie on a flat bench and take a narrow grip on an EZ bar, holding it over your chest with arms straight and elbows tucked in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_EZ-Bar_Press/0.jpg',
    ),
    Exercise(
      id: 'Decline_Close-Grip_Bench_To_Skull_Crusher',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Decline Close-Grip Bench To Skull Crusher',
      description:
          'Secure your legs at the end of a decline bench and lie back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Close-Grip_Bench_To_Skull_Crusher/0.jpg',
    ),
    Exercise(
      id: 'Decline_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Decline Dumbbell Triceps Extension',
      description:
          'Secure your legs on a decline bench and lie back with a dumbbell in each hand, palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Decline_EZ_Bar_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Decline EZ Bar Triceps Extension',
      description:
          'Secure your legs at the end of a decline bench and lie back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_EZ_Bar_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Dip_Machine',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Dip Machine',
      description:
          'Sit securely in the dip machine and grasp the handles with elbows bent about 90 degrees.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dip_Machine/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_One-Arm_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Dumbbell One-Arm Triceps Extension',
      description:
          'Sit or stand tall and raise a dumbbell overhead in one hand with the arm fully extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_One-Arm_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Tricep_Extension_-Pronated_Grip',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Dumbbell Tricep Extension -Pronated Grip',
      description:
          'Lie flat on a bench with two dumbbells pressed above your shoulders, arms extended and palms facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Tricep_Extension_-Pronated_Grip/0.jpg',
    ),
    Exercise(
      id: 'EZ-Bar_Skullcrusher',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'EZ-Bar Skullcrusher',
      description:
          'Lie on a bench holding the EZ-bar over the forehead with elbows fixed.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/EZ-Bar_Skullcrusher/0.jpg',
    ),
    Exercise(
      id: 'Incline_Barbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Incline Barbell Triceps Extension',
      description:
          'Lie back on an incline bench set between 45 and 75 degrees, holding a barbell with an overhand grip just inside shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Barbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'JM_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'JM Press',
      description:
          'Lie on a flat bench and hold a barbell at arm\'s length with a close grip and elbows tucked.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/JM_Press/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_Cable_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Kneeling Cable Triceps Extension',
      description:
          'Set a straight bar on a high pulley and kneel facing away from the machine, gripping the bar overhead with palms down and hands about six inches apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Cable_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Low_Cable_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Low Cable Triceps Extension',
      description:
          'Lie face up on the bench of a low cable row with your head pointing toward the rope attachment.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Low_Cable_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Lying_Close-Grip_Barbell_Triceps_Extension_Behind_The_Head',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Lying Close-Grip Barbell Triceps Extension Behind The Head',
      description:
          'Lie on a flat bench with your head near the end, holding a barbell with a overhand shoulder-width grip and arms extended over your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Close-Grip_Barbell_Triceps_Extension_Behind_The_Head/0.jpg',
    ),
    Exercise(
      id: 'Lying_Close-Grip_Barbell_Triceps_Press_To_Chin',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Lying Close-Grip Barbell Triceps Press To Chin',
      description:
          'Lie on a flat bench with your head off the end, holding an EZ bar with a overhand grip and arms extended over your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Close-Grip_Barbell_Triceps_Press_To_Chin/0.jpg',
    ),
    Exercise(
      id: 'Lying_Dumbbell_Tricep_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Lying Dumbbell Tricep Extension',
      description:
          'Lie flat on a bench holding two dumbbells over your chest with arms extended and palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Dumbbell_Tricep_Extension/0.jpg',
    ),
    Exercise(
      id: 'Lying_Triceps_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Lying Triceps Press',
      description:
          'Lie on a bench holding the bar over the chest with a close grip and elbows fixed.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Triceps_Press/0.jpg',
    ),
    Exercise(
      id: 'Machine_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Machine Triceps Extension',
      description:
          'Adjust the seat and set your upper arms against the pads, grasping the handles.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'One_Arm_Pronated_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'One Arm Pronated Dumbbell Triceps Extension',
      description:
          'Lie flat on a bench holding a dumbbell in one hand at arm\'s length, the arm perpendicular to your body and palm facing your feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Pronated_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'One_Arm_Supinated_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'One Arm Supinated Dumbbell Triceps Extension',
      description:
          'Lie flat on a bench and press a dumbbell straight up in one hand, palm facing your face.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Supinated_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Pin_Presses',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Pin Presses',
      description:
          'Set a bench in a power rack with the safety pins at your chosen height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pin_Presses/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Grip_Triceps_Pushdown',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Reverse Grip Triceps Pushdown',
      description:
          'Set a straight bar on a high pulley and grip it palms-up at shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Grip_Triceps_Pushdown/0.jpg',
    ),
    Exercise(
      id: 'Seated_Bent-Over_One-Arm_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Seated Bent-Over One-Arm Dumbbell Triceps Extension',
      description:
          'Sit at the end of a flat bench with a dumbbell in one hand, palm facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Bent-Over_One-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Seated_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Seated Bent-Over Two-Arm Dumbbell Triceps Extension',
      description:
          'Sit at the end of a flat bench with a dumbbell in each hand, palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Seated_Triceps_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Seated Triceps Press',
      description:
          'Sit on a bench with back support and hold one dumbbell overhead with both hands, arms locked out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Triceps_Press/0.jpg',
    ),
    Exercise(
      id: 'Sled_Overhead_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Sled Overhead Triceps Extension',
      description:
          'Attach dual handles to a loaded sled and face away from it, stepping out until the line is tight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Overhead_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Speed_Band_Overhead_Triceps',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Speed Band Overhead Triceps',
      description:
          'Anchor a band at floor level and face away from it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Speed_Band_Overhead_Triceps/0.jpg',
    ),
    Exercise(
      id: 'Standing_Bent-Over_One-Arm_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing Bent-Over One-Arm Dumbbell Triceps Extension',
      description:
          'Stand holding a dumbbell in one hand with your palm facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Bent-Over_One-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Standing_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing Bent-Over Two-Arm Dumbbell Triceps Extension',
      description:
          'Stand holding a dumbbell in each hand with palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Standing_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing Dumbbell Triceps Extension',
      description:
          'Stand with feet shoulder width and hold one dumbbell overhead with both hands, arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Standing_Low-Pulley_One-Arm_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing Low-Pulley One-Arm Triceps Extension',
      description:
          'Stand with your back to a low pulley and grab the single handle in one hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Low-Pulley_One-Arm_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Standing_One-Arm_Dumbbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing One-Arm Dumbbell Triceps Extension',
      description:
          'Stand with feet shoulder width and press a dumbbell overhead in one hand, arm fully extended with the pinky up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_One-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Standing_Overhead_Barbell_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing Overhead Barbell Triceps Extension',
      description:
          'Stand with feet shoulder width and hold a barbell overhead with a overhand grip, hands closer than shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Overhead_Barbell_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Standing_Towel_Triceps_Extension',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Standing Towel Triceps Extension',
      description:
          'Stand tall and hold one end of a towel with both hands, arms fully extended overhead and palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Towel_Triceps_Extension/0.jpg',
    ),
    Exercise(
      id: 'Tate_Press',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Tate Press',
      description:
          'Lie on a flat bench and press two dumbbells above your chest with palms facing forward and elbows flared out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tate_Press/0.jpg',
    ),
    Exercise(
      id: 'Triceps_Pushdown',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Triceps Pushdown',
      description:
          'Stand at a high pulley with the elbows pinned to the sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Triceps_Pushdown/0.jpg',
    ),
    Exercise(
      id: 'Triceps_Pushdown_-_Rope_Attachment',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Triceps Pushdown - Rope Attachment',
      description:
          'Attach a rope to a high pulley and grip it with palms facing each other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Triceps_Pushdown_-_Rope_Attachment/0.jpg',
    ),
    Exercise(
      id: 'Triceps_Pushdown_-_V-Bar_Attachment',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Triceps Pushdown - V-Bar Attachment',
      description:
          'Attach a V-bar to a high pulley and take an overhand grip at shoulder width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Triceps_Pushdown_-_V-Bar_Attachment/0.jpg',
    ),
    Exercise(
      id: 'Weighted_Bench_Dip',
      category: ExerciseCategory.other,
      muscles: ['Triceps'],
      name: 'Weighted Bench Dip',
      description:
          'Grip the edge of a bench behind you with hands shoulder width and rest your heels on a second bench ahead.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Bench_Dip/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Lunge',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Barbell Lunge',
      description:
          'With the bar on the upper back, step forward and lower until the back knee is just off the floor and the front thigh is parallel.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Lunge/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Walking_Lunge',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Barbell Walking Lunge',
      description:
          'With the bar on the upper back, step forward into a lunge, then drive through the front heel and step straight into the next lunge, alternating legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Walking_Lunge/0.jpg',
    ),
    Exercise(
      id: 'Bodyweight_Walking_Lunge',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Bodyweight Walking Lunge',
      description:
          'Stand tall with feet shoulder width and hands on your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Walking_Lunge/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Lunges',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Dumbbell Lunges',
      description:
          'Stand tall holding a dumbbell in each hand at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lunges/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Rear_Lunge',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Dumbbell Rear Lunge',
      description:
          'Stand tall holding a dumbbell in each hand at your sides.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Rear_Lunge/0.jpg',
    ),
    Exercise(
      id: 'Elevated_Back_Lunge',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Elevated Back Lunge',
      description:
          'Rack a barbell across your upper back and stand on a low raised platform with both feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elevated_Back_Lunge/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Turkish_Get-Up_Lunge_style',
      category: ExerciseCategory.squat,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Hamstrings', 'Core'],
      name: 'Kettlebell Turkish Get-Up (Lunge style)',
      description:
          'Lie on your back and press a kettlebell straight up with one arm, locking the elbow.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Turkish_Get-Up_Lunge_style/0.jpg',
    ),
    Exercise(
      id: 'Lunge_Pass_Through',
      category: ExerciseCategory.squat,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Core'],
      name: 'Lunge Pass Through',
      description:
          'Stand holding a kettlebell in one hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lunge_Pass_Through/0.jpg',
    ),
    Exercise(
      id: 'Lunge_Sprint',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Hamstrings', 'Core', 'Cardio'],
      name: 'Lunge Sprint',
      description:
          'Rack a Smith machine bar across your upper back and split your stance with one foot forward and one back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lunge_Sprint/0.jpg',
    ),
    Exercise(
      id: 'Step-up_with_Knee_Raise',
      category: ExerciseCategory.squat,
      muscles: ['Glutes', 'Quadriceps', 'Hamstrings', 'Core'],
      name: 'Step-up with Knee Raise',
      description:
          'Place one full foot on a box, drive through that heel to stand up onto it, and raise the opposite knee.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Step-up_with_Knee_Raise/0.jpg',
    ),
    Exercise(
      id: 'Bottoms-Up_Clean_From_The_Hang_Position',
      category: ExerciseCategory.other,
      muscles: [
        'Forearms',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Bottoms-Up Clean From The Hang Position',
      description:
          'Stand holding a kettlebell in one hand at hang position between your thighs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bottoms-Up_Clean_From_The_Hang_Position/0.jpg',
    ),
    Exercise(
      id: 'Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Clean',
      description:
          'Set up over a barbell with an overhand grip just outside your legs, hips down, back flat and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean/0.jpg',
    ),
    Exercise(
      id: 'Clean_Pull',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Clean Pull',
      description:
          'Set up over a barbell with an overhand or hook grip just outside your legs, hips down, back flat and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_Pull/0.jpg',
    ),
    Exercise(
      id: 'Clean_and_Jerk',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'Clean and Jerk',
      description:
          'Clean the bar to the shoulders, then dip slightly and drive it overhead with the legs, splitting or squatting under to catch it locked out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_and_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Clean_and_Press',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'Clean and Press',
      description:
          'Set up over a barbell with a overhand grip slightly wider than shoulder width, hips down and back flat.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_and_Press/0.jpg',
    ),
    Exercise(
      id: 'Clean_from_Blocks',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Clean from Blocks',
      description:
          'Set the barbell on blocks at the desired height and grip just outside your legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_from_Blocks/0.jpg',
    ),
    Exercise(
      id: 'Double_Kettlebell_Alternating_Hang_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Double Kettlebell Alternating Hang Clean',
      description:
          'Set two kettlebells between your feet, push your hips back, and clean one to your shoulder while the other hangs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Alternating_Hang_Clean/0.jpg',
    ),
    Exercise(
      id: 'Double_Kettlebell_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'Double Kettlebell Snatch',
      description:
          'Set two kettlebells behind your feet, bend the knees, and sit back to grip them.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Snatch/0.jpg',
    ),
    Exercise(
      id: 'Hang_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Hang Clean',
      description:
          'Hold the bar at mid-thigh with a shoulder-width overhand or hook grip, back flat and torso leaning slightly forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Clean/0.jpg',
    ),
    Exercise(
      id: 'Hang_Clean_-_Below_the_Knees',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Hang Clean - Below the Knees',
      description:
          'Hold the bar just below the knees with a shoulder-width overhand or hook grip, back flat and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Clean_-_Below_the_Knees/0.jpg',
    ),
    Exercise(
      id: 'Hang_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Hang Snatch',
      description:
          'Take a wide overhand or hook grip with the bar at the hips, feet under the hips and turned out, spine extended and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Snatch/0.jpg',
    ),
    Exercise(
      id: 'Hang_Snatch_-_Below_Knees',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Hang Snatch - Below Knees',
      description:
          'Take a wide overhand or hook grip with the bar just below the knees, feet under the hips and torso leaning forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Snatch_-_Below_Knees/0.jpg',
    ),
    Exercise(
      id: 'Heaving_Snatch_Balance',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Heaving Snatch Balance',
      description:
          'Rest a light bar across the back of your shoulders with a wide snatch grip, feet just wider than hips and turned out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Heaving_Snatch_Balance/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Dead_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Kettlebell Dead Clean',
      description:
          'Set a kettlebell between your feet, push your hips back, and grip it with eyes forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Dead_Clean/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Hang_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Kettlebell Hang Clean',
      description:
          'Hold a kettlebell at a hang with your hips pushed back and eyes forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Hang_Clean/0.jpg',
    ),
    Exercise(
      id: 'Muscle_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Muscle Snatch',
      description:
          'Hold the loaded bar at mid-thigh with a wide grip, hips low, chest up, and head forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Muscle_Snatch/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'One-Arm Kettlebell Clean',
      description:
          'Place a kettlebell between your feet, push your hips back, and grip it one-handed with eyes forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Clean/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Clean_and_Jerk',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'One-Arm Kettlebell Clean and Jerk',
      description:
          'Clean the kettlebell to your shoulder by extending through the legs and hips, rotating the palm to face forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Clean_and_Jerk/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'One-Arm Kettlebell Snatch',
      description:
          'Set a kettlebell between your feet, bend the knees, and sit the hips back with eyes forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Snatch/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Split_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'One-Arm Kettlebell Split Snatch',
      description:
          'Hold a kettlebell in one hand and squat toward the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Split_Snatch/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Open_Palm_Kettlebell_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'One-Arm Open Palm Kettlebell Clean',
      description:
          'Set one kettlebell between your feet and hinge down to grip the handle with one hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Open_Palm_Kettlebell_Clean/0.jpg',
    ),
    Exercise(
      id: 'Open_Palm_Kettlebell_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Open Palm Kettlebell Clean',
      description:
          'Straddle one kettlebell and hinge down to grasp the handle.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Open_Palm_Kettlebell_Clean/0.jpg',
    ),
    Exercise(
      id: 'Power_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Power Clean',
      description:
          'From a deadlift setup, pull the bar explosively past the knees, extend the hips, ankles and knees, then whip the elbows through to catch the bar on the front of the shoulders in a partial squat.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Clean/0.jpg',
    ),
    Exercise(
      id: 'Power_Clean_from_Blocks',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Power Clean from Blocks',
      description:
          'Set the bar on blocks and take a grip just outside your legs, hips down, back flat, shoulders over the bar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Clean_from_Blocks/0.jpg',
    ),
    Exercise(
      id: 'Power_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Power Snatch',
      description:
          'Stand over the bar with a wide grip, feet under your hips, hips down and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Snatch/0.jpg',
    ),
    Exercise(
      id: 'Power_Snatch_from_Blocks',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Power Snatch from Blocks',
      description:
          'Set the bar on blocks and take a wide grip, feet under your hips, hips down with chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Snatch_from_Blocks/0.jpg',
    ),
    Exercise(
      id: 'Rack_Delivery',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'Rack Delivery',
      description:
          'Hold the bar in the scarecrow position with your upper arms parallel to the floor and forearms hanging down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rack_Delivery/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Hang_Power_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Smith Machine Hang Power Clean',
      description:
          'Unhook the loaded Smith bar at knee height with a overhand grip just outside your shoulders, arms straight, chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Hang_Power_Clean/0.jpg',
    ),
    Exercise(
      id: 'Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Snatch',
      description:
          'From a wide grip, pull the bar explosively from the floor, extend the hips and pull under to catch it overhead in a full squat, then stand to lockout.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch/0.jpg',
    ),
    Exercise(
      id: 'Snatch_Balance',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Snatch Balance',
      description:
          'Rack the bar across your back with a wide snatch grip and feet in the pulling position.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Balance/0.jpg',
    ),
    Exercise(
      id: 'Snatch_Pull',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Snatch Pull',
      description:
          'Set up over the bar with a wide snatch grip, hips down, back flat, shoulders just ahead of the bar.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Pull/0.jpg',
    ),
    Exercise(
      id: 'Snatch_from_Blocks',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Snatch from Blocks',
      description:
          'Set the bar on blocks and take a wide grip, feet under your hips, hips down and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_from_Blocks/0.jpg',
    ),
    Exercise(
      id: 'Split_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Split Clean',
      description:
          'Set up over the bar with an overhand grip just outside your legs, hips down and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Clean/0.jpg',
    ),
    Exercise(
      id: 'Split_Snatch',
      category: ExerciseCategory.other,
      muscles: [
        'Hamstrings',
        'Quadriceps',
        'Glutes',
        'Lower back',
        'Traps',
        'Shoulders',
        'Core',
      ],
      name: 'Split Snatch',
      description:
          'Stand over the bar with a wide grip, feet under your hips, hips down and chest up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Snatch/0.jpg',
    ),
    Exercise(
      id: 'Two-Arm_Kettlebell_Clean',
      category: ExerciseCategory.other,
      muscles: [
        'Shoulders',
        'Quadriceps',
        'Glutes',
        'Hamstrings',
        'Lower back',
        'Traps',
        'Core',
      ],
      name: 'Two-Arm Kettlebell Clean',
      description:
          'Set two kettlebells between your feet and hinge back with your chest up, one handle in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Clean/0.jpg',
    ),
    Exercise(
      id: 'Alternate_Leg_Diagonal_Bound',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Alternate Leg Diagonal Bound',
      description:
          'Stand with one foot slightly ahead of the other.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Leg_Diagonal_Bound/0.jpg',
    ),
    Exercise(
      id: 'Backward_Medicine_Ball_Throw',
      category: ExerciseCategory.other,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Backward Medicine Ball Throw',
      description:
          'Stand holding a medicine ball down in front of you with both hands, feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Backward_Medicine_Ball_Throw/0.jpg',
    ),
    Exercise(
      id: 'Bench_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Bench Jump',
      description:
          'Stand a foot or two from a low bench, feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Jump/0.jpg',
    ),
    Exercise(
      id: 'Bench_Sprint',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core', 'Cardio'],
      name: 'Bench Sprint',
      description:
          'Stand tall with one foot planted on top of a bench, heel near the edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Sprint/0.jpg',
    ),
    Exercise(
      id: 'Box_Jump_Multiple_Response',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Box Jum',
      description:
          'Face the box about an arm\'s length away with knees slightly bent and arms low.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Jump_Multiple_Response/0.jpg',
    ),
    Exercise(
      id: 'Box_Skip',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Box Skip',
      description:
          'Set boxes in a line and face the first with one leg slightly back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Skip/0.jpg',
    ),
    Exercise(
      id: 'Carioca_Quick_Step',
      category: ExerciseCategory.other,
      muscles: ['Adductors', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Carioca Quick Step',
      description:
          'Stand tall with your feet a few inches apart and move to the side.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Carioca_Quick_Step/0.jpg',
    ),
    Exercise(
      id: 'Catch_and_Overhead_Throw',
      category: ExerciseCategory.other,
      muscles: ['Lats', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Catch and Overhead Throw',
      description:
          'Stand facing a wall or partner holding a medicine ball.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Catch_and_Overhead_Throw/0.jpg',
    ),
    Exercise(
      id: 'Chest_Push_multiple_response',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Chest Push (multiple response)',
      description:
          'Kneel tall facing a wall or partner with a medicine ball held tight to your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_multiple_response/0.jpg',
    ),
    Exercise(
      id: 'Chest_Push_single_response',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Chest Push (single response)',
      description:
          'Kneel with a medicine ball pressed tight to your chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_single_response/0.jpg',
    ),
    Exercise(
      id: 'Chest_Push_from_3_point_stance',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Chest Push from 3 point stance',
      description:
          'Set up in a three-point stance, squatted low with a flat back and one hand down beside the ball.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_from_3_point_stance/0.jpg',
    ),
    Exercise(
      id: 'Chest_Push_with_Run_Release',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Chest Push with Run Release',
      description:
          'Start in an athletic stance with knees bent, hips back, and the medicine ball held low by your legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_with_Run_Release/0.jpg',
    ),
    Exercise(
      id: 'Depth_Jump_Leap',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Depth Jump Leap',
      description:
          'Stand on the lower box with feet together near the edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Depth_Jump_Leap/0.jpg',
    ),
    Exercise(
      id: 'Double_Leg_Butt_Kick',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Double Leg Butt Kick',
      description:
          'Stand with knees slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Leg_Butt_Kick/0.jpg',
    ),
    Exercise(
      id: 'Drop_Push',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Drop Push',
      description:
          'Set two low boxes or platforms two to three feet apart and take a pushup position between them, a hand on each box.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Drop_Push/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Seated_Box_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Dumbbell Seated Box Jump',
      description:
          'Sit on a bench facing a box with a dumbbell held to your chest in both hands and feet planted firmly.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Seated_Box_Jump/0.jpg',
    ),
    Exercise(
      id: 'Fast_Skipping',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core', 'Cardio'],
      name: 'Fast Skipping',
      description:
          'Start relaxed with one leg slightly forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Fast_Skipping/0.jpg',
    ),
    Exercise(
      id: 'Freehand_Jump_Squat',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Freehand Jump Squat',
      description:
          'Cross your arms over your chest and set your feet shoulder-width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Freehand_Jump_Squat/0.jpg',
    ),
    Exercise(
      id: 'Front_Box_Jump',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Front Box Jump',
      description:
          'Set a box one to two feet in front of you and stand with feet shoulder-width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Box_Jump/0.jpg',
    ),
    Exercise(
      id: 'Front_Cone_Hops_or_hurdle_hops',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Front Cone Hops (or hurdle hops)',
      description:
          'Line up several cones a few feet apart and stand facing the first with feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Cone_Hops_or_hurdle_hops/0.jpg',
    ),
    Exercise(
      id: 'Heavy_Bag_Thrust',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Heavy Bag Thrust',
      description:
          'Stand tall beside the heavy bag with your feet staggered and wide, and place your hand on the bag at chest height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Heavy_Bag_Thrust/0.jpg',
    ),
    Exercise(
      id: 'Hurdle_Hops',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Hurdle Hops',
      description:
          'Set up a row of hurdles a few feet apart and stand facing the first with feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hurdle_Hops/0.jpg',
    ),
    Exercise(
      id: 'Isometric_Chest_Squeezes',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Isometric Chest Squeezes',
      description:
          'Stand or sit tall and bend both arms to ninety degrees, pressing your palms together in front of your chest with fingers pointing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Chest_Squeezes/0.jpg',
    ),
    Exercise(
      id: 'Knee_Tuck_Jump',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Knee Tuck Jump',
      description:
          'Stand with knees slightly bent and hold your palms down at chest height as a target.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Knee_Tuck_Jump/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_Arm_Drill',
      category: ExerciseCategory.other,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Kneeling Arm Drill',
      description:
          'Kneel with your left foot forward and right knee down, pressing through the front heel to keep your glutes tight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Arm_Drill/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_Jump_Squat',
      category: ExerciseCategory.other,
      muscles: ['Glutes', 'Quadriceps', 'Calves', 'Core'],
      name: 'Kneeling Jump Squat',
      description:
          'Kneel tall with a barbell racked across your shoulders and toes tucked under.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Jump_Squat/0.jpg',
    ),
    Exercise(
      id: 'Lateral_Bound',
      category: ExerciseCategory.other,
      muscles: ['Adductors', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Lateral Bound',
      description:
          'Stand in a half squat with your body facing ninety degrees from your travel direction.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Bound/0.jpg',
    ),
    Exercise(
      id: 'Lateral_Box_Jump',
      category: ExerciseCategory.other,
      muscles: ['Adductors', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Lateral Box Jump',
      description:
          'Stand tall beside a short box with feet hip-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Box_Jump/0.jpg',
    ),
    Exercise(
      id: 'Lateral_Cone_Hops',
      category: ExerciseCategory.other,
      muscles: ['Adductors', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Lateral Cone Hops',
      description:
          'Line up cones a few feet apart and stand at one end facing ninety degrees to the line.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Cone_Hops/0.jpg',
    ),
    Exercise(
      id: 'Linear_3-Part_Start_Technique',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Linear 3-Part Start Technique',
      description:
          'Start with both feet on a line, then step your left toe back level with your right ankle to stagger your stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Linear_3-Part_Start_Technique/0.jpg',
    ),
    Exercise(
      id: 'Linear_Acceleration_Wall_Drill',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Linear Acceleration Wall Drill',
      description:
          'Lean into a wall at about forty-five degrees with your feet together and glutes squeezed tight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Linear_Acceleration_Wall_Drill/0.jpg',
    ),
    Exercise(
      id: 'Linear_Depth_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Linear Depth Jump',
      description:
          'Stand on top of one box facing the second platform a few feet away.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Linear_Depth_Jump/0.jpg',
    ),
    Exercise(
      id: 'Medicine_Ball_Chest_Pass',
      category: ExerciseCategory.other,
      muscles: ['Chest', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Medicine Ball Chest Pass',
      description:
          'Face a partner or wall holding a medicine ball at your chest, elbows tucked.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Medicine_Ball_Chest_Pass/0.jpg',
    ),
    Exercise(
      id: 'Medicine_Ball_Full_Twist',
      category: ExerciseCategory.other,
      muscles: ['Core', 'Quadriceps', 'Glutes', 'Calves'],
      name: 'Medicine Ball Full Twist',
      description:
          'Stand back to back with a partner a couple feet apart, holding the ball at your trunk.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Medicine_Ball_Full_Twist/0.jpg',
    ),
    Exercise(
      id: 'Medicine_Ball_Scoop_Throw',
      category: ExerciseCategory.other,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Medicine Ball Scoop Throw',
      description:
          'Stand in a semisquat with a medicine ball hanging between your legs near your feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Medicine_Ball_Scoop_Throw/0.jpg',
    ),
    Exercise(
      id: 'Mountain_Climbers',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Mountain Climbers',
      description:
          'Start in a pushup position with hands under shoulders and one knee drawn up under your hip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Mountain_Climbers/0.jpg',
    ),
    Exercise(
      id: 'Moving_Claw_Series',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Moving Claw Series',
      description:
          'Move forward with a running action, flexing the knee to kick your heel toward your glutes as the hip extends.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Moving_Claw_Series/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Medicine_Ball_Slam',
      category: ExerciseCategory.other,
      muscles: ['Core', 'Quadriceps', 'Glutes', 'Calves'],
      name: 'One-Arm Medicine Ball Slam',
      description:
          'Stand in a staggered stance holding a medicine ball in one hand on your back-leg side.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Medicine_Ball_Slam/0.jpg',
    ),
    Exercise(
      id: 'Overhead_Slam',
      category: ExerciseCategory.other,
      muscles: ['Lats', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Overhead Slam',
      description:
          'Stand with feet shoulder-width holding a medicine ball in both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Overhead_Slam/0.jpg',
    ),
    Exercise(
      id: 'Quick_Leap',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Quick Leap',
      description:
          'Stand facing a box a foot or two from its edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Quick_Leap/0.jpg',
    ),
    Exercise(
      id: 'Return_Push_from_Stance',
      category: ExerciseCategory.other,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Return Push from Stance',
      description:
          'Set up in an athletic two- or three-point stance facing a partner.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Return_Push_from_Stance/0.jpg',
    ),
    Exercise(
      id: 'Rocket_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Rocket Jump',
      description:
          'Stand relaxed with feet shoulder-width and arms held close to your body.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rocket_Jump/0.jpg',
    ),
    Exercise(
      id: 'Rope_Jumping',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core', 'Cardio'],
      name: 'Rope Jumping',
      description:
          'Hold a rope handle in each hand with the rope behind your heels.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Jumping/0.jpg',
    ),
    Exercise(
      id: 'Scissors_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Scissors Jump',
      description:
          'Drop into a lunge with one foot forward, front knee bent over the midfoot and the rear knee near the ground.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Scissors_Jump/0.jpg',
    ),
    Exercise(
      id: 'Side_Hop-Sprint',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core', 'Cardio'],
      name: 'Side Hop-Sprint',
      description:
          'Stand to one side of a cone or low hurdle with feet together.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Hop-Sprint/0.jpg',
    ),
    Exercise(
      id: 'Side_Standing_Long_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Side Standing Long Jump',
      description:
          'Stand in an athletic stance with feet hip-width, chest up and knees slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Standing_Long_Jump/0.jpg',
    ),
    Exercise(
      id: 'Side_to_Side_Box_Shuffle',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Side to Side Box Shuffle',
      description:
          'Stand to one side of a box with your left foot resting on top of it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_to_Side_Box_Shuffle/0.jpg',
    ),
    Exercise(
      id: 'Single_Leg_Butt_Kick',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Single Leg Butt Kick',
      description:
          'Balance on one leg with the opposite knee lifted.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Leg_Butt_Kick/0.jpg',
    ),
    Exercise(
      id: 'Single_Leg_Push-off',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Single Leg Push-off',
      description:
          'Set one foot flat on a low box with the heel near the edge and the other foot on the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Leg_Push-off/0.jpg',
    ),
    Exercise(
      id: 'Single-Cone_Sprint_Drill',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core', 'Cardio'],
      name: 'Single-Cone Sprint Drill',
      description:
          'Stand beside a single cone with one arm forward and one back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Cone_Sprint_Drill/0.jpg',
    ),
    Exercise(
      id: 'Single-Leg_Hop_Progression',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Single-Leg Hop Progression',
      description:
          'Line up several low cones ahead of you and balance on one leg with the opposite knee raised.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Hop_Progression/0.jpg',
    ),
    Exercise(
      id: 'Single-Leg_Lateral_Hop',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Single-Leg Lateral Hop',
      description:
          'Stand to one side of a low cone, balanced on one leg with the knee slightly bent.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Lateral_Hop/0.jpg',
    ),
    Exercise(
      id: 'Single-Leg_Stride_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Single-Leg Stride Jump',
      description:
          'Stand beside a box with your inside foot on top near the edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Stride_Jump/0.jpg',
    ),
    Exercise(
      id: 'Sledgehammer_Swings',
      category: ExerciseCategory.other,
      muscles: ['Core', 'Quadriceps', 'Glutes', 'Calves'],
      name: 'Sledgehammer Swings',
      description:
          'Stand about two feet from a tire in a staggered stance, gripping a sledgehammer with your bottom hand at the base of the handle.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sledgehammer_Swings/0.jpg',
    ),
    Exercise(
      id: 'Split_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Split Jump',
      description:
          'Drop into a lunge with the front knee bent over your foot and the rear knee nearly touching the floor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Jump/0.jpg',
    ),
    Exercise(
      id: 'Standing_Long_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Standing Long Jump',
      description:
          'Stand in a partial squat with feet shoulder width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Long_Jump/0.jpg',
    ),
    Exercise(
      id: 'Standing_Two-Arm_Overhead_Throw',
      category: ExerciseCategory.other,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Standing Two-Arm Overhead Throw',
      description:
          'Stand with feet shoulder width apart holding a medicine ball in both hands.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Two-Arm_Overhead_Throw/0.jpg',
    ),
    Exercise(
      id: 'Star_Jump',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Star Jump',
      description:
          'Stand with feet shoulder width apart and arms held close to your body.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Star_Jump/0.jpg',
    ),
    Exercise(
      id: 'Stride_Jump_Crossover',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Stride Jump Crossover',
      description:
          'Stand beside a box with your inside foot on top near the edge.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stride_Jump_Crossover/0.jpg',
    ),
    Exercise(
      id: 'Supine_Chest_Throw',
      category: ExerciseCategory.other,
      muscles: ['Triceps', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Supine Chest Throw',
      description:
          'Lie on your back with knees bent and hold a medicine ball on your chest, hands on the bottom of the ball.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Supine_Chest_Throw/0.jpg',
    ),
    Exercise(
      id: 'Supine_One-Arm_Overhead_Throw',
      category: ExerciseCategory.other,
      muscles: ['Core', 'Quadriceps', 'Glutes', 'Calves'],
      name: 'Supine One-Arm Overhead Throw',
      description:
          'Lie on your back with knees bent, holding a medicine ball in one hand with the arm extended fully behind your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Supine_One-Arm_Overhead_Throw/0.jpg',
    ),
    Exercise(
      id: 'Supine_Two-Arm_Overhead_Throw',
      category: ExerciseCategory.other,
      muscles: ['Core', 'Quadriceps', 'Glutes', 'Calves'],
      name: 'Supine Two-Arm Overhead Throw',
      description:
          'Lie on your back with knees bent, holding a medicine ball in both hands with the arms extended fully behind your head.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Supine_Two-Arm_Overhead_Throw/0.jpg',
    ),
    Exercise(
      id: 'Vertical_Swing',
      category: ExerciseCategory.other,
      muscles: ['Hamstrings', 'Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Vertical Swing',
      description:
          'Grip one dumbbell with both hands, arms hanging between your legs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Vertical_Swing/0.jpg',
    ),
    Exercise(
      id: 'Weighted_Jump_Squat',
      category: ExerciseCategory.other,
      muscles: ['Quadriceps', 'Glutes', 'Calves', 'Core'],
      name: 'Weighted Jump Squat',
      description:
          'Set a lightly loaded barbell across your upper back and stand with feet shoulder-width apart.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Jump_Squat/0.jpg',
    ),
    Exercise(
      id: 'Backward_Drag',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Backward Drag',
      description:
          'Load a sled and hold the rope or straps with arms extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Backward_Drag/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Side_Split_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Barbell Side Split Squat',
      description:
          'Rest a barbell across your upper back and stand with feet wide, lead foot angled out to the side.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Side_Split_Squat/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Barbell Squat',
      description:
          'Set the bar just below shoulder height, step under it and rest it across your upper back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Squat_To_A_Bench',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Barbell Squat To A Bench',
      description:
          'Set a flat bench or box behind you and unrack a barbell across your upper back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat_To_A_Bench/0.jpg',
    ),
    Exercise(
      id: 'Barbell_Step_Ups',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Barbell Step Ups',
      description:
          'Hold a barbell across your upper back and stand facing an elevated platform.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Step_Ups/0.jpg',
    ),
    Exercise(
      id: 'Bear_Crawl_Sled_Drags',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Bear Crawl Sled Drags',
      description:
          'Strap a harness around your waist with the sled chained behind you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bear_Crawl_Sled_Drags/0.jpg',
    ),
    Exercise(
      id: 'Bicycling',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Bicycling',
      description:
          'Set the saddle so your leg is almost straight at the bottom of the pedal stroke.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bicycling/0.jpg',
    ),
    Exercise(
      id: 'Bicycling_Stationary',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Bicycling, Stationary',
      description:
          'Adjust the seat so your knee stays slightly bent at the bottom of each stroke.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bicycling_Stationary/0.jpg',
    ),
    Exercise(
      id: 'Bodyweight_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Bodyweight Squat',
      description:
          'Stand with feet shoulder-width apart and hands behind your head or out in front.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Squat/0.jpg',
    ),
    Exercise(
      id: 'Box_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Box Squat',
      description:
          'Set a box at about parallel height behind you and unrack a barbell across your upper back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Squat/0.jpg',
    ),
    Exercise(
      id: 'Box_Squat_with_Chains',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Box Squat with Chains',
      description:
          'Drape chains over the barbell sleeves, unrack it across your upper back, and set a box behind you at parallel height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Squat_with_Chains/0.jpg',
    ),
    Exercise(
      id: 'Calf_Press_On_The_Leg_Press_Machine',
      category: ExerciseCategory.squat,
      muscles: ['Calves', 'Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Calf Press On The Leg Press Machine',
      description:
          'Sit in the leg press and place just the balls of your feet on the lower edge of the platform, heels off.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Press_On_The_Leg_Press_Machine/0.jpg',
    ),
    Exercise(
      id: 'Chair_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Chair Squat',
      description:
          'Set the machine bar to your height and load it, then step under and position it across the back of your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chair_Squat/0.jpg',
    ),
    Exercise(
      id: 'Conans_Wheel',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Conan\'s Wheel',
      description:
          'Load the implement and cradle its end in the crooks of your elbows, gripping your own wrists.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Conans_Wheel/0.jpg',
    ),
    Exercise(
      id: 'Elliptical_Trainer',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Elliptical Trainer',
      description:
          'Step onto the pedals and take hold of the moving handles.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elliptical_Trainer/0.jpg',
    ),
    Exercise(
      id: 'Frankenstein_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Frankenstein Squat',
      description:
          'Rest the barbell across the front of your shoulders and extend both arms straight out, releasing your grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Frankenstein_Squat/0.jpg',
    ),
    Exercise(
      id: 'Front_Barbell_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Front Barbell Squat',
      description:
          'Rack the bar across the front of the shoulders with the elbows high, take a shoulder-width stance and brace.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Barbell_Squat/0.jpg',
    ),
    Exercise(
      id: 'Front_Barbell_Squat_To_A_Bench',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Front Barbell Squat To A Bench',
      description:
          'Set a flat bench behind you and rack the bar across the front of your shoulders with elbows high.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Barbell_Squat_To_A_Bench/0.jpg',
    ),
    Exercise(
      id: 'Front_Squat_Clean_Grip',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Front Squat',
      description:
          'Rack the bar on your front delts with a clean grip, fingers under the bar and elbows pointed high.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Squat_Clean_Grip/0.jpg',
    ),
    Exercise(
      id: 'Front_Squats_With_Two_Kettlebells',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Front Squats With Two Kettlebells',
      description:
          'Clean two kettlebells to your shoulders and rest them in the front rack with elbows tucked in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Squats_With_Two_Kettlebells/0.jpg',
    ),
    Exercise(
      id: 'Goblet_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Goblet Squat',
      description:
          'Hold a dumbbell or kettlebell vertically against the chest.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Goblet_Squat/0.jpg',
    ),
    Exercise(
      id: 'Hack_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Hack Squat',
      description:
          'Set your shoulders and back against the pad with feet shoulder-width on the platform.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hack_Squat/0.jpg',
    ),
    Exercise(
      id: 'Hip_Flexion_with_Band',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Hip Flexion with Band',
      description:
          'Attach a band to a low post and secure the other end around one ankle, then face away from the anchor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hip_Flexion_with_Band/0.jpg',
    ),
    Exercise(
      id: 'Jefferson_Squats',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Jefferson Squats',
      description:
          'Straddle the barbell so it runs between your legs, then grip it with one hand in front and one behind, palms neutral.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jefferson_Squats/0.jpg',
    ),
    Exercise(
      id: 'Jogging_Treadmill',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Jogging, Treadmill',
      description:
          'Step onto the treadmill deck and set a comfortable jogging speed.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jogging_Treadmill/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Turkish_Get-Up_Squat_style',
      category: ExerciseCategory.squat,
      muscles: ['Shoulders', 'Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Kettlebell Turkish Get-Up',
      description:
          'Lie on your back and press one kettlebell to a locked-out arm above your shoulder.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Turkish_Get-Up_Squat_style/0.jpg',
    ),
    Exercise(
      id: 'Kneeling_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Glutes', 'Quadriceps', 'Adductors', 'Core'],
      name: 'Kneeling Squat',
      description:
          'Rack a barbell across your upper back and kneel upright on a padded surface with knees hip-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Squat/0.jpg',
    ),
    Exercise(
      id: 'Leg_Press',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Leg Press',
      description:
          'Sit with the back flat against the pad and feet shoulder-width on the platform.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Press/0.jpg',
    ),
    Exercise(
      id: 'Lying_Machine_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Lying Machine Squat',
      description:
          'Lie face up in the machine with your feet on the platform and knees bent so the thighs sit just below parallel.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Machine_Squat/0.jpg',
    ),
    Exercise(
      id: 'Narrow_Stance_Hack_Squats',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Narrow Stance Hack Squats',
      description:
          'Set your back against the pad and hook your shoulders under the pads.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Narrow_Stance_Hack_Squats/0.jpg',
    ),
    Exercise(
      id: 'Narrow_Stance_Leg_Press',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Narrow Stance Leg Press',
      description:
          'Sit in the leg press and place your feet on the platform close together, a few inches apart, with toes slightly out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Narrow_Stance_Leg_Press/0.jpg',
    ),
    Exercise(
      id: 'Narrow_Stance_Squats',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Narrow Stance Squats',
      description:
          'Rack the bar across your upper back and step out with a narrow, closer-than-shoulder-width stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Narrow_Stance_Squats/0.jpg',
    ),
    Exercise(
      id: 'Olympic_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Olympic Squat',
      description:
          'Support the bar high on your traps with chest up and a hip-width stance, toes turned slightly out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Olympic_Squat/0.jpg',
    ),
    Exercise(
      id: 'One_Leg_Barbell_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'One Leg Barbell Squat',
      description:
          'Set a loaded barbell across your upper back and stand a couple feet in front of a bench, back facing it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Leg_Barbell_Squat/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Overhead_Kettlebell_Squats',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'One-Arm Overhead Kettlebell Squats',
      description:
          'Clean and press one kettlebell to a locked-out position overhead, arm by your ear.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Overhead_Kettlebell_Squats/0.jpg',
    ),
    Exercise(
      id: 'Overhead_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Overhead Squat',
      description:
          'Take a wide snatch grip and press the barbell to full lockout overhead, feet slightly wider than the shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Overhead_Squat/0.jpg',
    ),
    Exercise(
      id: 'Plie_Dumbbell_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Plie Dumbbell Squat',
      description:
          'Hold a single dumbbell vertically by one end with both hands, arms hanging straight.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plie_Dumbbell_Squat/0.jpg',
    ),
    Exercise(
      id: 'Recumbent_Bike',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Recumbent Bike',
      description:
          'Sit down on the recumbent bike and adjust the seat to your height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Recumbent_Bike/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Band_Box_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Reverse Band Box Squat',
      description:
          'Set bands from the top of the rack down to the bar so they pull upward, and place a box behind you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Box_Squat/0.jpg',
    ),
    Exercise(
      id: 'Reverse_Band_Power_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Reverse Band Power Squat',
      description:
          'Attach bands from the top of the rack to each end of the bar so they pull up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Power_Squat/0.jpg',
    ),
    Exercise(
      id: 'Running_Treadmill',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Running, Treadmill',
      description:
          'Step onto the treadmill deck and select a program or manual speed from the menu.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Running_Treadmill/0.jpg',
    ),
    Exercise(
      id: 'Sandbag_Load',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Sandbag Load',
      description:
          'Straddle the sandbag and squat down, wrapping both arms fully underneath it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sandbag_Load/0.jpg',
    ),
    Exercise(
      id: 'Single-Leg_High_Box_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Single-Leg High Box Squat',
      description:
          'Set a high box in a rack with a band or rope hanging above for balance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_High_Box_Squat/0.jpg',
    ),
    Exercise(
      id: 'Skating',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Skating',
      description:
          'Stand with skates hip width and knees soft, weight centered over the wheels.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Skating/0.jpg',
    ),
    Exercise(
      id: 'Sled_Drag_-_Harness',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Sled Drag',
      description:
          'Load the sled and buckle the harness around your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Drag_-_Harness/0.jpg',
    ),
    Exercise(
      id: 'Sled_Push',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Sled Push',
      description:
          'Load the sled and grip the handles with your arms fully extended.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Push/0.jpg',
    ),
    Exercise(
      id: 'Smith_Single-Leg_Split_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Smith Single-Leg Split Squat',
      description:
          'Set a bench a couple feet behind the Smith machine and position the bar across your upper back.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Single-Leg_Split_Squat/0.jpg',
    ),
    Exercise(
      id: 'Speed_Box_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Speed Box Squat',
      description:
          'Anchor bands from the floor to each end of the loaded bar and set a box behind you at about parallel height.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Speed_Box_Squat/0.jpg',
    ),
    Exercise(
      id: 'Speed_Squats',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Speed Squats',
      description:
          'Set the bar across your upper back in a squat rack and step out with feet shoulder-width, toes slightly out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Speed_Squats/0.jpg',
    ),
    Exercise(
      id: 'Split_Squat_with_Dumbbells',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Split Squat with Dumbbells',
      description:
          'Hold a dumbbell in each hand and set up in a staggered stance with the top of your rear foot resting on a bench behind you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Squat_with_Dumbbells/0.jpg',
    ),
    Exercise(
      id: 'Squat_with_Chains',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Squat with Chains',
      description:
          'Drape a chain over each sleeve of the bar so a few links rest on the floor at the top.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squat_with_Chains/0.jpg',
    ),
    Exercise(
      id: 'Squat_with_Plate_Movers',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Squat with Plate Movers',
      description:
          'Set the bar just below shoulder height and place a weight plate on the floor a couple of feet behind the rack.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squat_with_Plate_Movers/0.jpg',
    ),
    Exercise(
      id: 'Squats_-_With_Bands',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Squats - With Bands',
      description:
          'Stand on the middle of the band with feet shoulder-width, then pull the ends up to rest on top of your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squats_-_With_Bands/0.jpg',
    ),
    Exercise(
      id: 'Stairmaster',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Stairmaster',
      description:
          'Step onto the stairmaster and select a manual setting or program, then start at an easy pace.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stairmaster/0.jpg',
    ),
    Exercise(
      id: 'Step_Mill',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Step Mill',
      description:
          'Step onto the stepmill and pick a manual setting or program at a comfortable pace.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Step_Mill/0.jpg',
    ),
    Exercise(
      id: 'Suspended_Split_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Suspended Split Squat',
      description:
          'Set the strap handles 18 to 30 inches off the floor and face away from the anchor.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Split_Squat/0.jpg',
    ),
    Exercise(
      id: 'Tire_Flip',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Tire Flip',
      description:
          'Squat down to the tire with your chest driving into it and grip under the tread.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tire_Flip/0.jpg',
    ),
    Exercise(
      id: 'Trail_Running_Walking',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Trail Running/Walking',
      description:
          'Head out on a trail in supportive shoes and start at an easy pace to warm up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Trail_Running_Walking/0.jpg',
    ),
    Exercise(
      id: 'Walking_Treadmill',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core', 'Cardio'],
      name: 'Treadmill Walking',
      description:
          'Step onto the treadmill and select a manual setting or program, then start the belt at a walking pace.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Walking_Treadmill/0.jpg',
    ),
    Exercise(
      id: 'Weighted_Sissy_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Weighted Sissy Squat',
      description:
          'Grip a squat rack upright with one hand and hold a weight plate against your chest with the other, feet shoulder-width and up on your toes.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Sissy_Squat/0.jpg',
    ),
    Exercise(
      id: 'Wide_Stance_Barbell_Squat',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Wide Stance Barbell Squat',
      description:
          'Set the bar across your upper back in a squat rack and unrack it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide_Stance_Barbell_Squat/0.jpg',
    ),
    Exercise(
      id: 'Zercher_Squats',
      category: ExerciseCategory.squat,
      muscles: ['Quadriceps', 'Glutes', 'Adductors', 'Core'],
      name: 'Zercher Squats',
      description:
          'Set the bar on a rack between waist and chest height and hook it into the crooks of your elbows.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Zercher_Squats/0.jpg',
    ),
    Exercise(
      id: 'Close-Grip_Front_Lat_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Close-Grip Front Lat Pulldown',
      description:
          'Sit with the thighs under the pads and take a close grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Front_Lat_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'Full_Range-Of-Motion_Lat_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Full Range-Of-Motion Lat Pulldown',
      description:
          'Attach a stirrup handle to each high pulley and grab them with arms crossed, palms facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Full_Range-Of-Motion_Lat_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'One_Arm_Lat_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'One Arm Lat Pulldown',
      description:
          'Attach a single handle to a high pulley and sit with the knee pad snug against your thighs.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Lat_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'Rope_Straight-Arm_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Rope Straight-Arm Pulldown',
      description:
          'Attach a rope to a high pulley and stand a couple feet back with a staggered stance.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Straight-Arm_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'Straight-Arm_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Straight-Arm Pulldown',
      description:
          'Grab a wide bar on a high pulley with an overhand grip wider than shoulder width and step back about two feet.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight-Arm_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'Underhand_Cable_Pulldowns',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Underhand Cable Pulldowns',
      description:
          'Sit at a pulldown station and lock your thighs under the knee pads.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Underhand_Cable_Pulldowns/0.jpg',
    ),
    Exercise(
      id: 'V-Bar_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'V-Bar Pulldown',
      description:
          'With the thighs anchored and a neutral V-bar grip, lean back slightly and pull the bar to the upper chest, driving the elbows down.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/V-Bar_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'Wide-Grip_Lat_Pulldown',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Wide-Grip Lat Pulldown',
      description:
          'Sit at the pulldown machine and secure your thighs under the pads.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Lat_Pulldown/0.jpg',
    ),
    Exercise(
      id: 'Wide-Grip_Pulldown_Behind_The_Neck',
      category: ExerciseCategory.verticalPull,
      muscles: ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      name: 'Wide-Grip Pulldown Behind The Neck',
      description:
          'Sit at the pulldown machine with your thighs under the pads and take the wide bar with a broad overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Pulldown_Behind_The_Neck/0.jpg',
    ),
    Exercise(
      id: 'Alternating_Kettlebell_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Alternating Kettlebell Press',
      description:
          'Clean two kettlebells to your shoulders in the rack position with palms facing in.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Kettlebell_Press/0.jpg',
    ),
    Exercise(
      id: 'Anti-Gravity_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Anti-Gravity Press',
      description:
          'Set a barbell on the floor behind an incline bench and lie face down on the pad.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Anti-Gravity_Press/0.jpg',
    ),
    Exercise(
      id: 'Arnold_Dumbbell_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Arnold Dumbbell Press',
      description:
          'Start with the dumbbells in front of the shoulders, palms facing you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Arnold_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'Bradford_Rocky_Presses',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Bradford/Rocky Presses',
      description:
          'Sit on a press bench and hold the barbell at front shoulder level with an overhand grip just wider than your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bradford_Rocky_Presses/0.jpg',
    ),
    Exercise(
      id: 'Cuban_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Cuban Press',
      description:
          'Stand holding a dumbbell in each hand.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cuban_Press/0.jpg',
    ),
    Exercise(
      id: 'Double_Kettlebell_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Double Kettlebell Jerk',
      description:
          'Clean two kettlebells to your shoulders in the rack position.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Double_Kettlebell_Push_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Double Kettlebell Push Press',
      description:
          'Clean two kettlebells to your shoulders in the rack position.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Push_Press/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_One-Arm_Shoulder_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Dumbbell One-Arm Shoulder Press',
      description:
          'Sit on a bench with back support and clean one dumbbell to shoulder height with your palm facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_One-Arm_Shoulder_Press/0.jpg',
    ),
    Exercise(
      id: 'Dumbbell_Shoulder_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Dumbbell Shoulder Press',
      description:
          'Seated or standing, start with the dumbbells at shoulder height, palms forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Shoulder_Press/0.jpg',
    ),
    Exercise(
      id: 'Jerk_Balance',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Jerk Balance',
      description:
          'Rack the barbell on your shoulders in the jerk position with your torso upright and feet split short.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jerk_Balance/0.jpg',
    ),
    Exercise(
      id: 'Kettlebell_Seesaw_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Kettlebell Seesaw Press',
      description:
          'Clean two kettlebells to your shoulders in the rack position.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Seesaw_Press/0.jpg',
    ),
    Exercise(
      id: 'Leverage_Shoulder_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Leverage Shoulder Press',
      description:
          'Set the seat so the handles rest near the top of your shoulders and load the pins.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Shoulder_Press/0.jpg',
    ),
    Exercise(
      id: 'Machine_Shoulder_Military_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Machine Shoulder (Military) Press',
      description:
          'Sit tall, select the weight, and grab the handles at shoulder height with elbows bent in line with your torso.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Shoulder_Military_Press/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'One-Arm Kettlebell Jerk',
      description:
          'Clean a kettlebell to your shoulder with your palm facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Jerk/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Military_Press_To_The_Side',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'One-Arm Kettlebell Military Press To The Side',
      description:
          'Clean a kettlebell to your shoulder with your palm facing inward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Military_Press_To_The_Side/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Para_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'One-Arm Kettlebell Para Press',
      description:
          'Clean a kettlebell to your shoulder with your palm facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Para_Press/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Push_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'One-Arm Kettlebell Push Press',
      description:
          'Clean a kettlebell to your shoulder with your palm facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Push_Press/0.jpg',
    ),
    Exercise(
      id: 'One-Arm_Kettlebell_Split_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'One-Arm Kettlebell Split Jerk',
      description:
          'Clean a kettlebell to your shoulder with your palm forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Split_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Power_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Quadriceps', 'Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Power Jerk',
      description:
          'Start with the barbell racked across your front shoulders and feet under your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Push_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Push Press',
      description:
          'Hold the bar on the front of the shoulders with a shoulder-width grip and elbows up.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Push_Press/0.jpg',
    ),
    Exercise(
      id: 'Push_Press_-_Behind_the_Neck',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Push Press - Behind the Neck',
      description:
          'Rack the barbell across your upper back behind your neck with feet under your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Push_Press_-_Behind_the_Neck/0.jpg',
    ),
    Exercise(
      id: 'Seated_Barbell_Military_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Seated Barbell Military Press',
      description:
          'Sit on a press bench and take a barbell at shoulder height with a overhand grip just wider than your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Barbell_Military_Press/0.jpg',
    ),
    Exercise(
      id: 'Seated_Cable_Shoulder_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Seated Cable Shoulder Press',
      description:
          'Sit at the cable station and grasp a handle in each hand at shoulder height, elbows bent about ninety degrees.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Cable_Shoulder_Press/0.jpg',
    ),
    Exercise(
      id: 'Seated_Dumbbell_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Seated Dumbbell Press',
      description:
          'Sit on a bench with back support and bring a dumbbell to each shoulder, palms facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'See-Saw_Press_Alternating_Side_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'See-Saw Press (Alternating Side Press)',
      description:
          'Stand tall with a dumbbell at each shoulder, palms facing you.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/See-Saw_Press_Alternating_Side_Press/0.jpg',
    ),
    Exercise(
      id: 'Sled_Overhead_Backward_Walk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Sled Overhead Backward Walk',
      description:
          'Attach two handles to a lightly loaded sled and face it.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Overhead_Backward_Walk/0.jpg',
    ),
    Exercise(
      id: 'Smith_Machine_Overhead_Shoulder_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Smith Machine Overhead Shoulder Press',
      description:
          'Set a bench with back support under the Smith bar and sit so the bar sits just above your shoulders.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Overhead_Shoulder_Press/0.jpg',
    ),
    Exercise(
      id: 'Split_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Quadriceps', 'Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Split Jerk',
      description:
          'Rack the bar across your front delts, feet under your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Squat_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Quadriceps', 'Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Squat Jerk',
      description:
          'Rack the bar across your front delts, feet under your hips.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squat_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Standing_Alternating_Dumbbell_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Standing Alternating Dumbbell Press',
      description:
          'Stand with a dumbbell at each shoulder, palms facing forward and elbows out.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Alternating_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'Standing_Barbell_Press_Behind_Neck',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Standing Barbell Press Behind Neck',
      description:
          'Set the bar in a rack at shoulder height and take a wide overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Barbell_Press_Behind_Neck/0.jpg',
    ),
    Exercise(
      id: 'Standing_Bradford_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Standing Bradford Press',
      description:
          'Rack the bar across your front shoulders with a shoulder-width overhand grip.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Bradford_Press/0.jpg',
    ),
    Exercise(
      id: 'Standing_Military_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Standing Military Press',
      description:
          'Hold the bar at the front of the shoulders, feet hip-width, glutes and abs braced.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Military_Press/0.jpg',
    ),
    Exercise(
      id: 'Standing_Palm-In_One-Arm_Dumbbell_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Standing Palm-In One-Arm Dumbbell Press',
      description:
          'Hold a dumbbell at one shoulder with a neutral grip, palm facing in, feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Palm-In_One-Arm_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'Standing_Palms-In_Dumbbell_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Standing Palms-In Dumbbell Press',
      description:
          'Stand with a dumbbell at each shoulder using a neutral grip, palms facing each other, feet shoulder-width.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Palms-In_Dumbbell_Press/0.jpg',
    ),
    Exercise(
      id: 'Two-Arm_Kettlebell_Jerk',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Two-Arm Kettlebell Jerk',
      description:
          'Clean two kettlebells to your shoulders in the rack position, palms facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Jerk/0.jpg',
    ),
    Exercise(
      id: 'Two-Arm_Kettlebell_Military_Press',
      category: ExerciseCategory.verticalPush,
      muscles: ['Shoulders', 'Triceps', 'Upper back', 'Core'],
      name: 'Two-Arm Kettlebell Military Press',
      description:
          'Clean two kettlebells to your shoulders in the rack position, palms facing forward.',
      difficulty: 3,
      treeOrder: 0,
      isLibrary: true,
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Military_Press/0.jpg',
    ),
  ];

  static const Map<String, ExerciseCoaching> _coaching = {
    'Farmers_Walk': ExerciseCoaching(
      howTo: [
        'Grip a heavy implement or a dumbbell in each hand at your sides, brace, and stand tall by driving through the heels.',
        'Walk a set distance with short, quick steps, keeping the torso upright.',
      ],
      formChecks: [
        'Back straight, head up, shoulders back',
        'Short fast steps',
        'Brace the core the whole way',
        'Keep breathing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8OtwXwrJizk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Farmers_Walk/0.jpg',
    ),
    'Rickshaw_Carry': ExerciseCoaching(
      howTo: [
        'Stand centered inside the frame and grip the handles at your sides.',
        'Drive through your heels to lift the frame off the ground, keeping your chest and head up.',
        'Walk forward with short, quick steps while squeezing the handles hard to hold the load.',
      ],
      formChecks: [
        'Crush the handles',
        'Chest and head tall',
        'Short quick steps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pRkHLluG-V8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rickshaw_Carry/0.jpg',
    ),
    'Yoke_Walk': ExerciseCoaching(
      howTo: [
        'Duck under the yoke and rack the crossbar across the back of your shoulders.',
        'Grip the uprights, arch your back, and stand tall by driving through your legs to lift it off the rack.',
        'Walk forward with fast, controlled steps while bracing hard the whole way.',
      ],
      formChecks: [
        'Rack the bar high on your traps',
        'Arch the back hard',
        'Stand tall, no forward lean',
        'Fast choppy steps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=36gUqF8k6KQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Yoke_Walk/0.jpg',
    ),
    'Dead_Bug': ExerciseCoaching(
      howTo: [
        'Lie on your back with arms reaching toward the ceiling and knees bent over your hips at 90 degrees.',
        'Press your lower back flat into the floor.',
        'Slowly lower one arm overhead and the opposite leg toward the floor, then return and switch sides.',
      ],
      formChecks: [
        'Pin lower back to floor',
        'Lower opposite arm and leg',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4XLEnwUr1d8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dead_Bug/0.jpg',
    ),
    'Pallof_Press': ExerciseCoaching(
      howTo: [
        'Set a cable handle to shoulder height and stand side-on, holding it at your chest with both hands.',
        'Step away to build tension.',
        'Press the handle straight out until your arms lock, resisting the pull that wants to twist you, then draw it back to your chest.',
      ],
      formChecks: [
        'Resist the pull to twist',
        'Keep hips and shoulders square',
        'Press straight from the chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HXrLaqNIkTs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pallof_Press/0.jpg',
    ),
    'Plank': ExerciseCoaching(
      howTo: [
        'Rest on the forearms and toes with the elbows directly under the shoulders.',
        'Hold a straight line from head to heels for time, squeezing the glutes and bracing the abs.',
      ],
      formChecks: [
        'Straight line from head to heels, no sag or pike',
        'Elbows under shoulders',
        'Brace the abs and squeeze the glutes',
        'Breathe steadily',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rerKy2AEHz4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plank/0.jpg',
    ),
    'Ab_Crunch_Machine': ExerciseCoaching(
      howTo: [
        'Sit on the machine with your feet hooked under the pads and grab the top handles.',
        'Brace your abs and crunch your torso down by curling your ribcage toward your hips.',
        'Squeeze at the bottom, then let the weight pull you back up under control.',
      ],
      formChecks: [
        'Curl ribs toward hips',
        'Drive with abs, not arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fuPFq2EYswE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ab_Crunch_Machine/0.jpg',
    ),
    'Air_Bike': ExerciseCoaching(
      howTo: [
        'Lie on your back with hands lightly beside your head and lift your shoulders off the floor.',
        'Bring one knee toward your chest as you rotate the opposite elbow to meet it.',
        'Switch sides in a pedaling motion, extending the free leg out straight.',
      ],
      formChecks: [
        'Twist elbow to opposite knee',
        'Don\'t yank the neck',
        'Fully straighten the free leg',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jKT7-9L935g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Air_Bike/0.jpg',
    ),
    'Alternate_Heel_Touchers': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees bent, feet flat and shoulder-width apart, and arms extended at your sides.',
        'Crunch your torso up and to one side, reaching your hand toward that heel.',
        'Return to center, then bend to the other side and touch that heel.',
      ],
      formChecks: [
        'Crunch to the side',
        'Reach for your heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QkkINJhNHT0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Heel_Touchers/0.jpg',
    ),
    'Barbell_Rollout_from_Bench': ExerciseCoaching(
      howTo: [
        'Kneel on a bench and take a narrow grip on a loaded barbell resting on the floor at the bench\'s end.',
        'Extend through your hips to slowly roll the bar forward, letting your body stretch out long.',
        'Pull with your abs to roll the bar back under your shoulders.',
      ],
      formChecks: [
        'Keep hips from sagging',
        'Roll out slow, stay long',
        'Pull back with the abs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=RVGYevyytlc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Rollout_from_Bench/0.jpg',
    ),
    'Barbell_Side_Bend': ExerciseCoaching(
      howTo: [
        'Stand with a barbell resting across the back of your shoulders and feet shoulder-width apart.',
        'Keep your back straight and head up as you bend sideways at the waist.',
        'Contract your obliques to pull yourself upright, then bend to the other side.',
      ],
      formChecks: [
        'Bend straight to the side',
        'No forward or back lean',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CnsLmYb6tTw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Side_Bend/0.jpg',
    ),
    'Bent_Press': ExerciseCoaching(
      howTo: [
        'Clean a kettlebell to your shoulder and turn the wrist in.',
        'Bracing that arm, bend your torso down and to the side, wedging your body under the bell until the arm locks out overhead.',
        'Once locked, straighten your legs to stand tall, then bend back to lower it.',
      ],
      formChecks: [
        'Keep the pressing arm rigid',
        'Bend away from the bell',
        'Eyes locked on the bell',
        'Stand by straightening the legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5LotsRybLtA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Press/0.jpg',
    ),
    'Bent-Knee_Hip_Raise': ExerciseCoaching(
      howTo: [
        'Lie flat with arms at your sides and knees bent to about 75 degrees, feet hovering off the floor.',
        'Use your lower abs to draw your knees toward your chest, curling your hips up off the ground.',
        'Squeeze at the top, then lower slowly without dropping your feet.',
      ],
      formChecks: [
        'Curl hips off the floor',
        'Use lower abs, not momentum',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VsK9rz0xNI4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent-Knee_Hip_Raise/0.jpg',
    ),
    'Bosu_Ball_Cable_Crunch_With_Side_Bends': ExerciseCoaching(
      howTo: [
        'Set two low cable handles and lie back over a Bosu ball centered in front of the machine, holding a handle by each side of your head.',
        'Crunch your torso straight up against the resistance.',
        'As you rise, bend toward one side to hit the obliques, then lower and alternate.',
      ],
      formChecks: [
        'Drape your spine over the Bosu',
        'Crunch up, then bend to a side',
        'Keep the cable under tension',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=B1knh5GGXgc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bosu_Ball_Cable_Crunch_With_Side_Bends/0.jpg',
    ),
    'Bottoms_Up': ExerciseCoaching(
      howTo: [
        'Lie on your back with legs straight and arms at your sides.',
        'Tuck your knees toward your chest by bending the hips and knees, then press your feet up toward the ceiling to curl your glutes and lower back off the floor.',
        'Reverse under control to the start.',
      ],
      formChecks: [
        'Press soles to the ceiling',
        'Lift hips, don\'t kick up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=skKkSXYyybo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bottoms_Up/0.jpg',
    ),
    'Butt-Ups': ExerciseCoaching(
      howTo: [
        'Set up in a forearm plank with elbows under your shoulders and your back slightly arched.',
        'Keeping your forearms planted, pike your hips and raise your glutes toward the ceiling by contracting your abs.',
        'Pause at the top, then lower back to the flat plank.',
      ],
      formChecks: [
        'Pike hips toward the ceiling',
        'Keep forearms planted',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=g-v6IgOT3JY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Butt-Ups/0.jpg',
    ),
    'Cable_Crunch': ExerciseCoaching(
      howTo: [
        'Kneel below a high pulley holding the rope by the head.',
        'Crunch down by flexing the spine and contracting the abs, bringing the elbows toward the thighs, then return under control.',
      ],
      formChecks: [
        'Round the spine, flex, don\'t just hip-fold',
        'Keep the hips fixed',
        'Drive with the abs, not the arms',
        'Don\'t go so heavy the lower back takes over',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kc0PRn372lo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Crunch/0.jpg',
    ),
    'Cable_Judo_Flip': ExerciseCoaching(
      howTo: [
        'Set a rope on the lowest pulley and stand side-on with a wide stance, gripping it with both hands.',
        'Twist your torso away from the machine, pulling the rope up and over your opposite shoulder like a judo throw.',
        'Rotate back down under control against the tension.',
      ],
      formChecks: [
        'Twist from the core',
        'Keep arms fairly straight',
        'Pull over the opposite shoulder',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=osrtPt105mE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Judo_Flip/0.jpg',
    ),
    'Cable_Reverse_Crunch': ExerciseCoaching(
      howTo: [
        'Attach an ankle strap to a low pulley and lie on a mat with your feet toward the machine, knees bent to 90 degrees and legs lifted.',
        'Curl your hips and knees toward your chest, lifting your pelvis off the floor against the cable.',
        'Lower slowly until your hips touch back down.',
      ],
      formChecks: [
        'Roll the pelvis up off the mat',
        'Curl hips in, not just the knees',
        'Resist the cable pulling you back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OdDUPN0JBBY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Reverse_Crunch/0.jpg',
    ),
    'Cable_Seated_Crunch': ExerciseCoaching(
      howTo: [
        'Sit on a bench with your back to a high pulley and hold the rope with both hands beside your head.',
        'Crunch straight down by rounding your spine and drawing your elbows toward your thighs.',
        'Squeeze the abs at the bottom, then rise slowly against the cable\'s pull.',
      ],
      formChecks: [
        'Round the spine toward your thighs',
        'Pull with abs, not the arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CGP-af-lmB0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Seated_Crunch/0.jpg',
    ),
    'Cocoons': ExerciseCoaching(
      howTo: [
        'Lie on your back with your legs straight and arms extended overhead.',
        'Tuck your knees toward your chest while rotating your pelvis to lift your hips off the floor, swinging your arms forward at the same time.',
        'Extend your body back out until you are long again.',
      ],
      formChecks: [
        'Swing arms and knees to meet',
        'Lift the hips as you tuck',
        'Reach long on the extension',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8Jtx3RCbZug',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cocoons/0.jpg',
    ),
    'Cross-Body_Crunch': ExerciseCoaching(
      howTo: [
        'Lie on your back with your knees bent and feet flat, hands loose behind your head.',
        'Curl up and twist to bring one elbow and shoulder across toward the opposite knee.',
        'Squeeze, lower back down, then alternate to the other side.',
      ],
      formChecks: [
        'Drive elbow to the opposite knee',
        'Twist from the waist, not the neck',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=En69Xp29Ecs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cross-Body_Crunch/0.jpg',
    ),
    'Crunch_-_Hands_Overhead': ExerciseCoaching(
      howTo: [
        'Lie on your back with your knees bent and feet flat, arms stretched overhead with palms crossed.',
        'Keeping your arms locked beside your ears, curl your shoulder blades off the floor by flexing your abs.',
        'Lower back down under control without dropping your arms.',
      ],
      formChecks: [
        'Keep arms locked beside your ears',
        'Lift with abs, no arm swing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JZopIwgE2UA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crunch_-_Hands_Overhead/0.jpg',
    ),
    'Crunch_-_Legs_On_Exercise_Ball': ExerciseCoaching(
      howTo: [
        'Lie on your back with your feet resting on an exercise ball, knees bent to 90 degrees and hands beside your head.',
        'Curl your shoulder blades up off the floor by flexing your abs while keeping the ball still.',
        'Lower slowly back to the floor.',
      ],
      formChecks: [
        'Hold the ball still as you curl',
        'Peel shoulder blades off the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xbA9ZuH5eOU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crunch_-_Legs_On_Exercise_Ball/0.jpg',
    ),
    'Crunches': ExerciseCoaching(
      howTo: [
        'Lie on your back with your knees bent and feet flat, holding a medicine ball against your chest.',
        'Curl your head, shoulders, and upper back off the floor by contracting your abs.',
        'Squeeze at the top, then lower slowly back down.',
      ],
      formChecks: [
        'Hug the ball to your chest',
        'Curl shoulders up, neck neutral',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=muUxqr87jUc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crunches/0.jpg',
    ),
    'Decline_Crunch': ExerciseCoaching(
      howTo: [
        'Hook your legs at the top of a decline bench and lie back with your hands beside your head, elbows in.',
        'Press your lower back into the bench and curl your shoulders up toward your hips by flexing your abs.',
        'Squeeze, then lower under control.',
      ],
      formChecks: [
        'Curl ribs toward your hips',
        'Hands off the neck, elbows in',
        'No swinging off the bench',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FRzQXeN1hro',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Crunch/0.jpg',
    ),
    'Decline_Oblique_Crunch': ExerciseCoaching(
      howTo: [
        'Hook your legs on a decline bench and lie back with one hand beside your head.',
        'Curl your torso up and twist, driving that elbow across toward the opposite knee until your obliques squeeze.',
        'Lower down with control, then work the other side.',
      ],
      formChecks: [
        'Twist elbow to the opposite knee',
        'Rotate the ribs, not the neck',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=p5FGLF2fFdk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Oblique_Crunch/0.jpg',
    ),
    'Decline_Reverse_Crunch': ExerciseCoaching(
      howTo: [
        'Lie head-up on a decline bench and grip the top behind your head.',
        'Hold your legs out with knees slightly bent, then curl your knees toward your chest and lift your hips off the bench by rolling your pelvis up.',
        'Lower your legs back down slowly.',
      ],
      formChecks: [
        'Roll the hips up off the bench',
        'Curl knees toward your chest',
        'Grip the bench behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=73BcWhbPTuw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Reverse_Crunch/0.jpg',
    ),
    'Elbow_to_Knee': ExerciseCoaching(
      howTo: [
        'Lie on your back and cross one ankle over the opposite bent knee, hands behind your head.',
        'Flex your spine and rotate to bring the opposite elbow toward the crossed knee until your obliques squeeze.',
        'Lower under control, then switch legs and sides.',
      ],
      formChecks: [
        'Bring elbow to the crossed knee',
        'Rotate the torso, not the neck',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eDpkD4MQ19I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elbow_to_Knee/0.jpg',
    ),
    'Exercise_Ball_Crunch': ExerciseCoaching(
      howTo: [
        'Lie back over an exercise ball with your lower back on the curve and feet flat on the floor.',
        'Let your torso drape back, then crunch up by flexing your abs and rolling your shoulders toward your hips.',
        'Lower back over the ball until you feel the abs stretch.',
      ],
      formChecks: [
        'Let the abs stretch over the ball',
        'Curl up rolling ribs to hips',
        'Keep the ball from rocking',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=O4d3kd1ZLyc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Exercise_Ball_Crunch/0.jpg',
    ),
    'Exercise_Ball_Pull-In': ExerciseCoaching(
      howTo: [
        'Get into a push-up position with your hands on the floor and shins on top of an exercise ball, body straight.',
        'Bend your knees and roll the ball toward you until your knees tuck under your chest.',
        'Straighten your legs to roll the ball back out to a plank.',
      ],
      formChecks: [
        'Hold a straight plank line',
        'Tuck knees to roll the ball in',
        'Straighten to roll it back out',
        'Keep hips from sagging',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3R81zuUD_L0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Exercise_Ball_Pull-In/0.jpg',
    ),
    'Flat_Bench_Leg_Pull-In': ExerciseCoaching(
      howTo: [
        'Lie back on a flat bench with your legs extended off the end, hands under your glutes or gripping the bench.',
        'Bend your knees and pull them in toward your chest by flexing your abs.',
        'Extend your legs back out straight and low without touching the floor.',
      ],
      formChecks: [
        'Pull knees in toward your chest',
        'Stop legs short of the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Vdoy8hgdeMQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Leg_Pull-In/0.jpg',
    ),
    'Flat_Bench_Lying_Leg_Raise': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench with your legs extended off the end and grip the bench beside your hips.',
        'Keeping your legs almost straight, raise them until they point toward the ceiling by contracting your lower abs.',
        'Lower them slowly until they are just above the bench.',
      ],
      formChecks: [
        'Raise straight legs toward the ceiling',
        'Stop short before feet touch down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3WbEUWavHtE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Lying_Leg_Raise/0.jpg',
    ),
    'Frog_Sit-Ups': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees dropped out to the sides and the soles of your feet together.',
        'Crunch your torso up off the floor, reaching your hands toward your feet and squeezing your abs.',
        'Lower under control until your shoulders touch down.',
      ],
      formChecks: [
        'Keep soles pinned together',
        'Reach hands past your feet',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=-rhFzkvUp14',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Frog_Sit-Ups/0.jpg',
    ),
    'Gorilla_Chin_Crunch': ExerciseCoaching(
      howTo: [
        'Hang from a chin-up bar with an underhand grip slightly wider than your shoulders and knees bent to 90 degrees.',
        'Curl your abs and pull with your arms to bring your knees up toward your elbows.',
        'Lower back to the hang under control.',
      ],
      formChecks: [
        'Grip underhand, past shoulder width',
        'Pull with arms as knees rise',
        'Meet knees to elbows',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kEYEU1j2zXM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Gorilla_Chin_Crunch/0.jpg',
    ),
    'Hanging_Pike': ExerciseCoaching(
      howTo: [
        'Hang from a chin-up bar with an overhand grip slightly wider than your shoulders and legs together.',
        'Keeping your legs straight, raise them in front of you toward the bar into a pike.',
        'Lower them slowly back to the hang.',
      ],
      formChecks: [
        'Keep legs locked straight',
        'Raise feet to the bar, no swing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IDbOHkGV6eU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Pike/0.jpg',
    ),
    'Jackknife_Sit-Up': ExerciseCoaching(
      howTo: [
        'Lie flat with your arms extended overhead and legs straight.',
        'Exhale and raise your legs and torso at the same time, reaching your hands toward your feet so your body forms a V.',
        'Lower your arms and legs back down under control.',
      ],
      formChecks: [
        'Raise legs and torso as one',
        'Keep legs straight, not bent',
        'Meet hands to feet up top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MRfVqjfKKUo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jackknife_Sit-Up/0.jpg',
    ),
    'Janda_Sit-Up': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees bent 90 degrees, feet flat, and arms crossed over your chest.',
        'Squeeze your glutes and dig your heels down, then curl your torso up using your abs.',
        'Lower slowly while keeping the glutes and hamstrings tight.',
      ],
      formChecks: [
        'Squeeze glutes the whole rep',
        'Dig heels into the floor',
        'Curl up using your abs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=178DdHjiDx4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Janda_Sit-Up/0.jpg',
    ),
    'Kettlebell_Figure_8': ExerciseCoaching(
      howTo: [
        'Take a wider than shoulder-width stance and hinge at the hips with a flat back, holding a kettlebell in one hand.',
        'Pass it between your legs to the other hand, then loop it around the outside of that leg and back through, tracing a figure-8 around your legs.',
      ],
      formChecks: [
        'Hinge with a flat back',
        'Pass the bell between your legs',
        'Loop it around each thigh',
        'Trace a smooth figure-8',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aqT3uigA4ns',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Figure_8/0.jpg',
    ),
    'Kettlebell_Pass_Between_The_Legs': ExerciseCoaching(
      howTo: [
        'Take a comfortable stance and hinge at the hips with your back flat, holding a kettlebell between your legs.',
        'Pass it from one hand to the other behind your legs, then bring your hands to the front and pass it back the other way.',
      ],
      formChecks: [
        'Hinge and keep your back flat',
        'Swap hands behind and in front',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_UIJbMphhaA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Pass_Between_The_Legs/0.jpg',
    ),
    'Knee_Hip_Raise_On_Parallel_Bars': ExerciseCoaching(
      howTo: [
        'Support yourself on the raise station with your forearms on the pads and back against the rest, legs hanging straight down.',
        'Raise your knees up toward your chest by curling your hips and contracting your abs.',
        'Lower them slowly to the hang.',
      ],
      formChecks: [
        'Curl your hips under, not just knees',
        'Keep your legs from swinging',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=2QLm7eVRtbM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Knee_Hip_Raise_On_Parallel_Bars/0.jpg',
    ),
    'Landmine_180s': ExerciseCoaching(
      howTo: [
        'Anchor a barbell in a landmine and raise the loaded end to shoulder height with both hands, arms extended, in a wide stance.',
        'Rotate your torso and sweep the bar in an arc from one side down to the other, pivoting your feet.',
        'Control the arc back across.',
      ],
      formChecks: [
        'Keep arms long and locked',
        'Pivot your feet with the arc',
        'Rotate from your core',
        'Control the bar side to side',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YC7poHGaVFE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Landmine_180s/0.jpg',
    ),
    'Leg_Pull-In': ExerciseCoaching(
      howTo: [
        'Lie on a mat with legs extended and hands beside your hips or under your glutes.',
        'Bend your knees and pull your thighs up toward your chest while lifting your hips slightly.',
        'Extend your legs back out straight without letting your heels touch the floor.',
      ],
      formChecks: [
        'Pull thighs toward your chest',
        'Lift your hips slightly',
        'Keep heels off the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4M9WAcIbLFE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Pull-In/0.jpg',
    ),
    'Oblique_Crunches': ExerciseCoaching(
      howTo: [
        'Lie on your back with feet elevated on a bench, one hand beside your head and the other out on the floor.',
        'Crunch up and twist, driving your elbow toward the opposite knee to work the oblique.',
        'Lower under control back down.',
      ],
      formChecks: [
        'Twist as you crunch up',
        'Drive elbow to opposite knee',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=teZDcxypX54',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Oblique_Crunches/0.jpg',
    ),
    'One-Arm_High-Pulley_Cable_Side_Bends': ExerciseCoaching(
      howTo: [
        'Set a handle to the highest pulley and stand side-on to the machine.',
        'Grab it with an underhand grip and pull it down to your shoulder.',
        'Bend sideways away from the cable, crunching your obliques to pull the weight down, then return upright under control.',
      ],
      formChecks: [
        'Stand side-on to the cable',
        'Bend away from the machine',
        'Pull with obliques, not your arm',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=keqotJ-qohs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_High-Pulley_Cable_Side_Bends/0.jpg',
    ),
    'Otis-Up': ExerciseCoaching(
      howTo: [
        'Secure your feet and lie back with your knees bent, holding a weight at your chest with both hands.',
        'Sit up by flexing the hips and spine, and press the weight overhead to lock out at the top.',
        'Lower it to your chest as you reverse down, stopping short of the floor.',
      ],
      formChecks: [
        'Press the weight overhead as you rise',
        'Sit up under control',
        'Don\'t flop back to the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gvGiqkAR0CE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Otis-Up/0.jpg',
    ),
    'Press_Sit-Up': ExerciseCoaching(
      howTo: [
        'Lie back with your legs secured and a barbell resting on your chest.',
        'Tighten your abs and sit your torso up while pressing the barbell straight overhead until your arms lock out.',
        'Reverse both movements to lower the bar and torso back down.',
      ],
      formChecks: [
        'Sit up as you press the bar',
        'Lock the bar overhead',
        'Reverse both on the way down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CrM9fcsUbI0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Press_Sit-Up/0.jpg',
    ),
    'Rope_Crunch': ExerciseCoaching(
      howTo: [
        'Kneel facing a high cable, grasp the rope overhead with both hands, and hold it beside your head with your torso upright.',
        'Crunch down by rounding your spine and driving your elbows toward your thighs until your abs squeeze hard.',
        'Return slowly under control.',
      ],
      formChecks: [
        'Round the spine, not the hips',
        'Drive your elbows to your thighs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6GMKPQVERzw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Crunch/0.jpg',
    ),
    'Seated_Flat_Bench_Leg_Pull-In': ExerciseCoaching(
      howTo: [
        'Sit on the end of a bench, grip the sides, and lean your torso back about 45 degrees with your legs extended straight and slightly below parallel.',
        'Pull your knees in toward your chest while crunching your torso forward to meet them.',
        'Extend your legs back out under control.',
      ],
      formChecks: [
        'Pull knees and torso together',
        'Keep your legs off the floor',
        'No rocking for momentum',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Vdoy8hgdeMQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Flat_Bench_Leg_Pull-In/0.jpg',
    ),
    'Seated_Leg_Tucks': ExerciseCoaching(
      howTo: [
        'Sit on a bench gripping the edges, torso leaning back near 45 degrees with legs stretched out below parallel.',
        'Tuck your knees in toward your torso and crunch your upper body forward to meet them.',
        'Straighten your legs back out under control.',
      ],
      formChecks: [
        'Curl knees and chest to meet',
        'Keep your feet off the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3bQjaXBGdDA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Leg_Tucks/0.jpg',
    ),
    'Side_Bridge': ExerciseCoaching(
      howTo: [
        'Lie on one side with the forearm under the shoulder and legs stacked.',
        'Lift the hips off the floor so the body forms a straight line from head to feet, and hold for time.',
        'Switch sides.',
      ],
      formChecks: [
        'Elbow directly under the shoulder',
        'Straight line, hips high, do not let them sag',
        'Brace the side of the core',
        'Keep the neck neutral',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=I8IY2_wSuSA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Bridge/0.jpg',
    ),
    'Side_Jackknife': ExerciseCoaching(
      howTo: [
        'Lie on one side with legs extended and the top hand behind the head.',
        'Raise the torso and top leg together so the elbow travels toward the leg, then lower under control.',
        'Switch sides.',
      ],
      formChecks: [
        'Move slowly and with control',
        'Squeeze the obliques at the top',
        'Do not pull on the neck',
        'Keep the motion in the waist, not the hips',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zoiKMH1bGag',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Jackknife/0.jpg',
    ),
    'Sit-Up': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees bent, feet anchored, and hands behind your head.',
        'Curl your torso up off the floor toward your knees, leading with your chest.',
        'Lower back down with control until your shoulders touch.',
      ],
      formChecks: [
        'Don\'t yank on your neck',
        'Roll up through the spine',
        'Lead with your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_EvMTkXme0g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sit-Up/0.jpg',
    ),
    'Smith_Machine_Hip_Raise': ExerciseCoaching(
      howTo: [
        'Lie on a bench set in a Smith machine and rest the bar against the soles of your feet with your legs extended up.',
        'Grip the bench behind your head, then raise your hips by curling your pelvis up and pushing the bar higher with your feet.',
        'Lower under control.',
      ],
      formChecks: [
        'Curl the hips up, don\'t leg-press',
        'Keep your legs near vertical',
        'Push the bar with your soles',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=wlbjBFnKLsA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Hip_Raise/0.jpg',
    ),
    'Spell_Caster': ExerciseCoaching(
      howTo: [
        'Stand with feet wide, holding a dumbbell in each hand with a palms-down grip.',
        'Pull both dumbbells to one hip while rotating your torso to that side, then sweep them across to the opposite hip through your waist.',
        'Alternate sides each rep.',
      ],
      formChecks: [
        'Pull the weights to one hip',
        'Rotate through your waist',
        'Sweep across to the other hip',
        'Keep arms level and softly bent',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oJ7SPCKeVY0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Spell_Caster/0.jpg',
    ),
    'Spider_Crawl': ExerciseCoaching(
      howTo: [
        'Get into a low push-up plank with your arms bent and body straight from head to heels.',
        'Bring one knee out to the side and up toward the same-side elbow.',
        'Return the leg, then repeat with the other side, crawling your knees to your elbows.',
      ],
      formChecks: [
        'Drive knee to the same-side elbow',
        'Keep hips low, don\'t sag',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Hdh1ZF1gskM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Spider_Crawl/0.jpg',
    ),
    'Standing_Cable_Lift': ExerciseCoaching(
      howTo: [
        'Set the cable to the lowest pulley and stand side-on, gripping the handle with both hands by your outside hip.',
        'Step away to load the cable, then sweep the handle up and across your body to above the opposite shoulder as you rotate your torso.',
        'Return under control.',
      ],
      formChecks: [
        'Sweep from hip to opposite shoulder',
        'Rotate from your core, not arms',
        'Keep your arms nearly straight',
        'Pivot your back foot as you lift',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dDYLiE2tOFM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Cable_Lift/0.jpg',
    ),
    'Standing_Rope_Crunch': ExerciseCoaching(
      howTo: [
        'Set a rope on a high pulley and stand with your back to the tower, holding the rope over your shoulders with the ends at your upper chest.',
        'Crunch forward by rounding your spine and pulling your ribs toward your pelvis.',
        'Return upright under control.',
      ],
      formChecks: [
        'Curl your ribs toward your pelvis',
        'Bend the spine, not the hips',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BHINEbPdpwE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Rope_Crunch/0.jpg',
    ),
    'Suspended_Fallout': ExerciseCoaching(
      howTo: [
        'Set suspension straps below waist height, grab a handle in each hand, and lean forward into an incline plank with arms extended in front.',
        'Keeping your arms straight and core braced, let your arms travel overhead as your body lowers.',
        'Pull back to the start using your abs.',
      ],
      formChecks: [
        'Keep your arms straight throughout',
        'Don\'t let your hips sag',
        'Only reach as far as you control',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9JfJSPhH-0U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Fallout/0.jpg',
    ),
    'Suspended_Reverse_Crunch': ExerciseCoaching(
      howTo: [
        'Place your feet in suspension handles set about a foot off the floor and get into a push-up plank facing away from the rack.',
        'With a straight body, tuck both knees in toward your chest by rounding your lower back.',
        'Extend your legs back to a plank under control.',
      ],
      formChecks: [
        'Round your low back to curl the hips',
        'Stack shoulders over your hands',
        'Don\'t let your hips drop',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=83RIwPpGBck',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Reverse_Crunch/0.jpg',
    ),
    'Tuck_Crunch': ExerciseCoaching(
      howTo: [
        'Lie on your back with your knees bent up and ankles crossed, arms resting at your sides.',
        'Crunch your upper body up off the floor toward your knees while keeping your legs tucked.',
        'Lower your shoulders back down under control.',
      ],
      formChecks: [
        'Reach your chest toward the knees',
        'Keep your legs tucked and still',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jXhCVgNYDow',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tuck_Crunch/0.jpg',
    ),
    'Weighted_Ball_Side_Bend': ExerciseCoaching(
      howTo: [
        'Drape one side of your torso over an exercise ball with your feet planted for support, holding a weight plate against the side of your head.',
        'Bend up and away from the ball by contracting your obliques, then lower back over the ball under control.',
      ],
      formChecks: [
        'Plate flat against your head',
        'Bend straight sideways, no twist',
        'Lift from the obliques',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rzjvTKQwvRw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Ball_Side_Bend/0.jpg',
    ),
    'Weighted_Sit-Ups_-_With_Bands': ExerciseCoaching(
      howTo: [
        'Anchor bands at the base of a decline bench, hook your legs under the pads, and lie back holding a handle at each shoulder.',
        'Sit up by curling your torso toward your knees against the band tension.',
        'Lower back down under control.',
      ],
      formChecks: [
        'Curl up against the band tension',
        'Fight the bands on the way down',
        'Keep the handles at your shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FQogbZX_JyY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Sit-Ups_-_With_Bands/0.jpg',
    ),
    'Wind_Sprints': ExerciseCoaching(
      howTo: [
        'Hang from a pull-up bar with an overhand grip and arms and legs fully extended.',
        'Quickly drive one knee up as high as you can toward your chest.',
        'Immediately switch, lowering that leg as you snap the other knee up, running your knees in the air.',
      ],
      formChecks: [
        'Drive each knee up high',
        'Don\'t swing from the bar',
        'Keep a fast, steady rhythm',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=tfcFT-EE5ss',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wind_Sprints/0.jpg',
    ),
    'Advanced_Kettlebell_Windmill': ExerciseCoaching(
      howTo: [
        'Clean and press a kettlebell overhead and lock it out.',
        'Tuck your free arm behind your back and turn your feet away from the bell.',
        'Push your hips toward the bell and bend sideways, lowering your torso as far as you can, then stand back up.',
      ],
      formChecks: [
        'Stack the bell over your shoulder',
        'Push your hips toward the bell',
        'Keep your eyes on the top bell',
        'Sink as deep as your hips allow',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MD6vOuRVmek',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Advanced_Kettlebell_Windmill/0.jpg',
    ),
    'Cable_Russian_Twists': ExerciseCoaching(
      howTo: [
        'Set a handle to a middle pulley and lie back on a stability ball with your side to the cable.',
        'Hold the handle with both hands, arms extended straight over your chest.',
        'Rotate your torso and arms away from the tower, then control the twist back.',
      ],
      formChecks: [
        'Keep your arms straight over your chest',
        'Rotate away from the tower',
        'Keep your hips lifted on the ball',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WjYjVAnJU7M',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Russian_Twists/0.jpg',
    ),
    'Double_Kettlebell_Windmill': ExerciseCoaching(
      howTo: [
        'Press one kettlebell overhead and lock it out, with a second bell resting by your front foot.',
        'Push your hips toward the top bell and hinge down to grip the low bell, keeping the top arm locked.',
        'Stand tall, then lower under control.',
      ],
      formChecks: [
        'Keep the top arm locked overhead',
        'Hinge down to grip the low bell',
        'Keep both legs long',
        'Watch the raised bell',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=E6ftrsUsZFc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Windmill/0.jpg',
    ),
    'Kettlebell_Windmill': ExerciseCoaching(
      howTo: [
        'Clean and press a kettlebell overhead and lock the arm out.',
        'Turn your feet away from the bell and push your hips toward it, hinging sideways to slide your free hand down your leg toward the floor.',
        'Keep the bell overhead and rise back up.',
      ],
      formChecks: [
        'Keep the bell locked overhead',
        'Slide your free hand down your leg',
        'Hinge at the hips, not the waist',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ITSmgn_BQgY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Windmill/0.jpg',
    ),
    'Kneeling_Cable_Crunch_With_Alternating_Oblique_Twists': ExerciseCoaching(
      howTo: [
        'Attach a rope to a high pulley and kneel a couple of feet back, holding the rope beside your head.',
        'Crunch down by rounding your spine and driving your elbows toward the floor.',
        'As you crunch, rotate to aim one elbow toward the opposite knee, alternating sides each rep.',
      ],
      formChecks: [
        'Crunch with your abs, not your arms',
        'Round your spine toward the floor',
        'Aim each elbow at the opposite knee',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sJ-QyxZ5lOU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Cable_Crunch_With_Alternating_Oblique_Twists/0.jpg',
    ),
    'Pallof_Press_With_Rotation': ExerciseCoaching(
      howTo: [
        'Set a handle to shoulder height and stand side-on, holding it at your chest with both hands.',
        'Press the handle straight out from your sternum, then rotate your torso away from the tower until your arms point away from it.',
        'Rotate back and pull the handle to your chest.',
      ],
      formChecks: [
        'Press straight out from your sternum',
        'Resist the cable twisting you back',
        'Keep your arms long as you rotate',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cvDSv8i2TJg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pallof_Press_With_Rotation/0.jpg',
    ),
    'Plate_Twist': ExerciseCoaching(
      howTo: [
        'Sit on the floor with your torso upright and hold a plate by its sides in front of your stomach.',
        'Lean back slightly and lift or cross your feet off the floor.',
        'Rotate your torso to sweep the plate toward the floor on one side, then twist across to the other side.',
      ],
      formChecks: [
        'Lean back with your feet raised',
        'Turn your shoulders to sweep the plate',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rfhFU-XX1WU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plate_Twist/0.jpg',
    ),
    'Russian_Twist': ExerciseCoaching(
      howTo: [
        'Sit with the knees bent and torso leaned back, feet up or down.',
        'Rotate the torso to touch the weight or hands to each side under control.',
      ],
      formChecks: [
        'Rotate through the trunk, not just the arms',
        'Keep the chest up and back braced',
        'Move under control, no flinging',
        'Keep the core tight throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=99T1EfpMwPA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Russian_Twist/0.jpg',
    ),
    'Seated_Barbell_Twist': ExerciseCoaching(
      howTo: [
        'Sit on the end of a flat bench with your feet shoulder-width apart and a barbell resting across the back of your shoulders.',
        'Grip the bar wide with palms facing down.',
        'Rotate your torso to one side, then twist smoothly to the other while keeping your hips square.',
      ],
      formChecks: [
        'Keep your hips and legs still',
        'Keep the bar level as you twist',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3Ho1g8h23wA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Barbell_Twist/0.jpg',
    ),
    'Standing_Cable_Wood_Chop': ExerciseCoaching(
      howTo: [
        'Set a handle to the top pulley and stand side-on, gripping it with both hands and arms extended up toward the tower.',
        'Pull the handle down and across your body to the opposite hip, rotating your torso and pivoting your back foot.',
        'Resist the load back up along the same path.',
      ],
      formChecks: [
        'Grip the handle high by the tower',
        'Chop down to your opposite hip',
        'Rotate through your torso',
        'Pivot your back foot',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=PCQCwP1Xy0g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Cable_Wood_Chop/0.jpg',
    ),
    'Atlas_Stone_Trainer': ExerciseCoaching(
      howTo: [
        'Load the trainer and straddle it with feet hip-width.',
        'Bend at the hips and knees to wrap your arms under the implement and lock your hands together.',
        'Drive through your legs and extend your hips to stand tall, hugging the load to your chest, then lower it back down.',
      ],
      formChecks: [
        'Lock your hands under the load',
        'Hug it tight to your chest',
        'Drive up through your legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=98e7wFsFx78',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Atlas_Stone_Trainer/0.jpg',
    ),
    'Atlas_Stones': ExerciseCoaching(
      howTo: [
        'Stand over the stone with it between your feet.',
        'Hinge at the hips and wrap your arms down around the stone, digging your fingers underneath it.',
        'Extend your hips and legs to lift it to your lap, then stand tall and drive the stone up, keeping it hugged tight to your chest.',
      ],
      formChecks: [
        'Dig your fingers under the stone',
        'Pull it onto your lap first',
        'Keep the stone against your body',
        'Extend your hips to stand tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=PTuiMF9K_C8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Atlas_Stones/0.jpg',
    ),
    'Axle_Deadlift': ExerciseCoaching(
      howTo: [
        'Set your feet hip-width with the axle over your midfoot.',
        'Hinge down and grip the thick bar at shoulder width using an over-under grip.',
        'Take the slack out, then drive through the floor and extend your hips and knees to stand tall with the bar, then lower it under control.',
      ],
      formChecks: [
        'Set the bar over your midfoot',
        'Grip hard with over-under hands',
        'Keep the bar against your shins',
        'Drive the floor away to stand',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6ekU3WqUkuE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Axle_Deadlift/0.jpg',
    ),
    'Band_Good_Morning_Pull_Through': ExerciseCoaching(
      howTo: [
        'Loop a band around a sturdy post and hook the other end behind your neck.',
        'Step out to add tension and set your feet hip-width.',
        'Push your hips back and hinge forward with a flat back until you feel your hamstrings stretch, then squeeze your glutes to stand tall.',
      ],
      formChecks: [
        'Push your hips back, not down',
        'Feel the stretch in your hamstrings',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=q0yX0yOsA4s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Good_Morning_Pull_Through/0.jpg',
    ),
    'Barbell_Deadlift': ExerciseCoaching(
      howTo: [
        'Set the bar over the mid-foot, hip-width stance, and grip just outside the knees.',
        'Take the slack out, flatten the back and brace, then push the floor away and stand tall, dragging the bar up the legs to a locked-out finish.',
      ],
      formChecks: [
        'Bar over the mid-foot, shins near the bar',
        'Flat back, chest up, lats tight',
        'Push the floor away rather than yanking',
        'Lock the hips and knees together at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5wGKjmq1uJ8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Deadlift/0.jpg',
    ),
    'Barbell_Glute_Bridge': ExerciseCoaching(
      howTo: [
        'Lie on the floor with the bar across the hips and knees bent.',
        'Drive through the heels to lift the hips until the body is straight from knees to shoulders, then lower.',
      ],
      formChecks: [
        'Drive through the heels',
        'Squeeze the glutes at the top',
        'Keep the ribs down, don\'t arch the back',
        'Chin tucked, eyes forward',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DQv1IMQDbE4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Glute_Bridge/0.jpg',
    ),
    'Barbell_Hip_Thrust': ExerciseCoaching(
      howTo: [
        'Sit with the upper back on a bench and the bar across the hips.',
        'Drive through the heels to lift the hips to a straight line from knees to shoulders, then lower under control.',
      ],
      formChecks: [
        'Tuck the chin and keep the ribs down',
        'Drive through the heels',
        'Squeeze the glutes hard at lockout',
        'Don\'t hyperextend the lower back at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5S8SApGU_Lk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Hip_Thrust/0.jpg',
    ),
    'Cable_Deadlifts': ExerciseCoaching(
      howTo: [
        'Set both cables to the lowest pulleys and stand between the towers.',
        'Squat down by bending your hips and knees to grab a handle from each side.',
        'Drive through your feet and extend your knees and hips to stand tall, then lower back into the squat under control.',
      ],
      formChecks: [
        'Sit your hips down to the handles',
        'Push the floor away to rise',
        'Keep tension on both cables',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=00rB7p-Wlxc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Deadlifts/0.jpg',
    ),
    'Car_Deadlift': ExerciseCoaching(
      howTo: [
        'Center yourself in the frame and take the neutral-grip handles at your sides.',
        'Set your feet flat, brace your core, and drop your hips to load your legs.',
        'Drive through the floor and extend your knees and hips to stand the apparatus up, then lower it under control.',
      ],
      formChecks: [
        'Center yourself between the handles',
        'Drop your hips to load your legs',
        'Chest up, back flat',
        'Drive through your whole foot',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UtJFQ4DVGAY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Car_Deadlift/0.jpg',
    ),
    'Clean_Deadlift': ExerciseCoaching(
      howTo: [
        'Set your feet hip-width under the bar with toes turned out slightly, and take a shoulder-width overhand or hook grip.',
        'Drop your hips low with your chest up and shoulders over the bar.',
        'Push through the floor and extend your hips and knees to stand tall, keeping the bar brushing your legs.',
      ],
      formChecks: [
        'Bar over midfoot, shins to the bar',
        'Hips low, shoulders over the bar',
        'Extend hips and knees together',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dO1XJXKxAs0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_Deadlift/0.jpg',
    ),
    'Deadlift_with_Chains': ExerciseCoaching(
      howTo: [
        'Drape chains over the bar or clip them to the sleeves so the load builds as you rise.',
        'Stand with feet hip-width, bar over midfoot, and grip just outside your knees.',
        'Set a flat back and brace, then drive through your heels and extend your hips to lockout as the links leave the floor.',
      ],
      formChecks: [
        'Let chains pile on the floor at the bottom',
        'Accelerate as the load builds up top',
        'Feet hip-width, bar over midfoot',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=RS6R7pAD6Ao',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Deadlift_with_Chains/0.jpg',
    ),
    'Deficit_Deadlift': ExerciseCoaching(
      howTo: [
        'Stand on a platform one to three inches high with the bar over your midfoot and feet hip-width.',
        'Bend at the hips and knees to grip just outside your legs, settling into the deeper start.',
        'Keep a flat back and drive through the floor to extend your hips and stand tall.',
      ],
      formChecks: [
        'Own the extra range off the platform',
        'Bar tracks close up the legs',
        'Reset the flat back each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CpWsUsqBtN8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Deficit_Deadlift/0.jpg',
    ),
    'Flutter_Kicks': ExerciseCoaching(
      howTo: [
        'Lie facedown on a bench with your hips at the edge and hold the front for support.',
        'Straighten your legs so your toes hang off the floor.',
        'Squeeze your glutes to lift both legs, then alternate kicking each leg up and down in small, quick pulses without touching the floor.',
      ],
      formChecks: [
        'Lift from the glutes, not the low back',
        'Keep both legs straight and pulsing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=K5wuM_gNWyw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flutter_Kicks/0.jpg',
    ),
    'Glute_Ham_Raise': ExerciseCoaching(
      howTo: [
        'Set your feet against the footplate between the rollers and lie facedown with your knees just behind the pad.',
        'Keep your back arched and body straight from knees to head.',
        'Lower your torso under control, then drive your toes into the plate and contract the hamstrings to pull back up.',
      ],
      formChecks: [
        'Straight line, knees to head',
        'Drive the toes into the plate',
        'Control the descent',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Or4NJdZKLC8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Glute_Ham_Raise/0.jpg',
    ),
    'Good_Morning': ExerciseCoaching(
      howTo: [
        'With the bar on the upper back and knees soft, push the hips back and hinge the torso toward parallel with a flat back.',
        'Reverse by driving the hips forward to stand.',
      ],
      formChecks: [
        'Hip hinge, not a squat',
        'Keep the back flat and braced',
        'Only go as low as the hamstrings allow',
        'Start light, this loads the lower back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nczH_7m1TnI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Good_Morning/0.jpg',
    ),
    'Good_Morning_off_Pins': ExerciseCoaching(
      howTo: [
        'Set the bar on pins at stomach height and rack it across the rear of your shoulders with a hip-width stance.',
        'From the bent-over bottom position, brace hard.',
        'Drive your hips forward and extend your back to stand tall, then hinge back down to rest the bar on the pins each rep.',
      ],
      formChecks: [
        'Start dead from the pins each rep',
        'Bar on rear delts, not the neck',
        'Push hips forward to stand',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FubluSoLsmk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Good_Morning_off_Pins/0.jpg',
    ),
    'Hanging_Bar_Good_Morning': ExerciseCoaching(
      howTo: [
        'Suspend the bar from chains or straps at stomach height and rack it across the rear of your shoulders.',
        'Take a hip-width stance and step back into the hanging bar.',
        'Hinge at your hips, pushing them back and lowering your chest, then drive your hips forward to stand tall while steadying the bar.',
      ],
      formChecks: [
        'Steady the swinging bar before you move',
        'Push hips back to hinge',
        'Keep the back flat throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dEJ0FTm-CEk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Bar_Good_Morning/0.jpg',
    ),
    'Hip_Extension_with_Bands': ExerciseCoaching(
      howTo: [
        'Attach a band to a low post and secure the other end to one ankle.',
        'Face the anchor and hold the post to steady yourself with your chest and head up.',
        'Keeping the working leg fairly straight, drive it back and up against the band by squeezing your glute, then return under control.',
      ],
      formChecks: [
        'Drive the leg back with the glute',
        'Keep the working leg fairly straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=teGzPFBYp5Q',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hip_Extension_with_Bands/0.jpg',
    ),
    'Hip_Lift_with_Band': ExerciseCoaching(
      howTo: [
        'Lie on your back in the middle of the rack with a band anchored on both sides running across your hips.',
        'Bend your knees and plant your feet flat.',
        'Drive through your heels and push your hips up against the band until your body forms a straight line, then lower under control.',
      ],
      formChecks: [
        'Push hips up until the body is straight',
        'Finish through the heels',
        'Keep ribs down, no overarch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EkOpRYgC7MI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hip_Lift_with_Band/0.jpg',
    ),
    'Hyperextensions_Back_Extensions': ExerciseCoaching(
      howTo: [
        'Lie facedown on a hyperextension bench with your ankles secured under the footpads and thighs flat across the pad.',
        'Cross your arms or place hands by your head.',
        'Bend forward at the waist to lower your torso, then contract your lower back and glutes to raise up in line with your legs.',
      ],
      formChecks: [
        'Round up one vertebra at a time',
        'Stop at level, no overextending',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gLT-WLH84B4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hyperextensions_Back_Extensions/0.jpg',
    ),
    'Hyperextensions_With_No_Hyperextension_Bench': ExerciseCoaching(
      howTo: [
        'Lie facedown on a flat bench with your hips at the edge and a partner holding your legs down.',
        'Let your upper body hang toward the floor.',
        'Bend at the waist to lower fully, then squeeze your lower back and glutes to raise your torso until it lines up with your legs.',
      ],
      formChecks: [
        'Partner pins your legs to the bench',
        'Raise only until torso is level',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ojsRo2FDCww',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hyperextensions_With_No_Hyperextension_Bench/0.jpg',
    ),
    'Keg_Load': ExerciseCoaching(
      howTo: [
        'Set the keg on its side and grip the near edge of the base, tilting it toward you to grab the far bottom edge.',
        'Hinge at your hips with a flat back and pull the keg into your chest.',
        'Extend your hips to stand, carry it in, and load it onto the platform.',
      ],
      formChecks: [
        'Hinge and hug the keg to your chest',
        'Stand up through hips and legs',
        'Keep the back flat, never rounded',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EN06n8Vyjmw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Keg_Load/0.jpg',
    ),
    'Kettlebell_One-Legged_Deadlift': ExerciseCoaching(
      howTo: [
        'Hold a kettlebell in one hand and stand on the same-side leg with a soft knee.',
        'Hinge at the hip, lowering the bell toward the floor while your free leg extends straight behind you for balance.',
        'Feel the hamstring stretch, then drive your hips forward to return to standing.',
      ],
      formChecks: [
        'Free leg extends straight behind you',
        'Keep hips and shoulders square',
        'Soft bend in the standing knee',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YJh7jVCYpho',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_One-Legged_Deadlift/0.jpg',
    ),
    'Leverage_Deadlift': ExerciseCoaching(
      howTo: [
        'Load the machine and stand between the handles with feet hip-width.',
        'Grasp the lower handles and drop your hips with your chest up and head looking forward.',
        'Take a breath and brace, then push through your legs and extend your hips and knees to stand tall, and lower under control.',
      ],
      formChecks: [
        'Grip the low handles, chest up',
        'Push through the legs to stand',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mpg46ejJxvo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Deadlift/0.jpg',
    ),
    'Natural_Glute_Ham_Raise': ExerciseCoaching(
      howTo: [
        'Anchor your ankles under the pads of a lat pulldown or preacher bench, knees on the seat, facing away and upright.',
        'Keeping a straight line from knees to head, lower your torso toward the floor as slowly as you can, then contract your hamstrings to pull yourself back up.',
      ],
      formChecks: [
        'Lower as slowly as you can resist',
        'Hamstrings fight the whole descent',
        'Push off hands only if needed',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=s8o_WXLQZCA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Natural_Glute_Ham_Raise/0.jpg',
    ),
    'One-Arm_Kettlebell_Swings': ExerciseCoaching(
      howTo: [
        'Stand with the kettlebell an arm\'s length in front, hinge at the hips and hike it back between the legs.',
        'Snap the hips forward to float the bell up to chest height, then let it fall back into the next hinge.',
      ],
      formChecks: [
        'Power comes from the hips, not the arms',
        'Keep the back flat and the arms relaxed',
        'Squeeze the glutes hard at the top',
        'Let the bell float, do not lift it with the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sxtfgmzhXvE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Swings/0.jpg',
    ),
    'One-Arm_Side_Deadlift': ExerciseCoaching(
      howTo: [
        'Stand alongside a loaded barbell with your feet next to its center.',
        'Bend your knees and hips to reach down and grip the bar\'s center with one hand, palm facing your leg like a suitcase handle.',
        'Drive through both legs to stand tall, then lower back under control.',
      ],
      formChecks: [
        'Grip the bar center one-handed',
        'Stay tall, resist tipping sideways',
        'Push through both legs evenly',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EBg-GWOS1CA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Side_Deadlift/0.jpg',
    ),
    'Physioball_Hip_Bridge': ExerciseCoaching(
      howTo: [
        'Lie with your upper back on an exercise ball and feet flat on the floor, hip width apart.',
        'Let your hips hang down below the ball.',
        'Squeeze your glutes to drive your hips up until your torso and thighs form a straight line, then lower under control.',
      ],
      formChecks: [
        'Steady the ball with your upper back',
        'Drive hips up to a straight line',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MRBMFFU2Ovc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Physioball_Hip_Bridge/0.jpg',
    ),
    'Power_Stairs': ExerciseCoaching(
      howTo: [
        'Set your feet wide and grip the implement with both hands, head and chest up.',
        'Hinge at the hips to load the hamstrings, then drive through the ground and extend your hips to lift the implement onto the step above.',
        'Advance up the staircase one step at a time.',
      ],
      formChecks: [
        'Set feet wide, chest tall',
        'Hinge back to load hamstrings',
        'Explode hips onto the next step',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=F32ZA_glI-w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Stairs/0.jpg',
    ),
    'Prowler_Sprint': ExerciseCoaching(
      howTo: [
        'Load the sled and grip the upright or low handles with your arms extended.',
        'Lean forward with a flat back and drive the sled ahead by sprinting, extending each leg fully behind you.',
        'Stay low and aggressive, pushing for the set distance.',
      ],
      formChecks: [
        'Lean in with arms locked',
        'Extend each leg fully behind',
        'Stay low, powerful strides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=awOpmrx_IS4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Prowler_Sprint/0.jpg',
    ),
    'Pull_Through': ExerciseCoaching(
      howTo: [
        'Straddle a low cable with a rope attachment, facing away a few feet from the machine with your feet set wide.',
        'Hinge at the hips and reach the rope back between your legs, letting your torso fold forward.',
        'Snap your hips forward and squeeze your glutes to stand tall.',
      ],
      formChecks: [
        'Reach rope back between your legs',
        'Snap hips forward, arms straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NO-NevrDrjE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pull_Through/0.jpg',
    ),
    'Rack_Pull_with_Bands': ExerciseCoaching(
      howTo: [
        'Set the bar on pins just below or above the knees in a power rack and anchor bands from the bar to the rack base.',
        'Set your feet, grip the bar, and take a deadlift stance with a flat back.',
        'Drive through the floor and extend your hips to lockout, then lower to the pins.',
      ],
      formChecks: [
        'Set bar at knee height on pins',
        'Drive hips hard to lockout',
        'Accelerate against rising band tension',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pgXG15RDrxU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rack_Pull_with_Bands/0.jpg',
    ),
    'Rack_Pulls': ExerciseCoaching(
      howTo: [
        'Set the bar on pins just below or above the knees in a power rack.',
        'Position your feet hip width under the bar and grip it in a deadlift stance with a flat back and chest up.',
        'Drive through your legs and extend your hips to pull the bar to lockout, then lower to the pins.',
      ],
      formChecks: [
        'Start with bar just below the knees',
        'Drag the bar up to lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=iS7SMtSr2-4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rack_Pulls/0.jpg',
    ),
    'Reverse_Band_Deadlift': ExerciseCoaching(
      howTo: [
        'Attach bands from the top of the rack to the bar so they take tension off the bottom of the lift.',
        'Stand with the bar over your midfoot, hinge down, and grip just outside your knees with a flat back.',
        'Drive through the floor to stand tall, then control the bar down.',
      ],
      formChecks: [
        'Set the bar over your midfoot',
        'Grip just outside your knees',
        'Drive harder as the bands release',
        'Meet the floaty bottom softly',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Qm7PSLGq-2o',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Deadlift/0.jpg',
    ),
    'Reverse_Band_Sumo_Deadlift': ExerciseCoaching(
      howTo: [
        'Anchor bands from the top of the rack to the barbell so they unload the bottom.',
        'Take a wide sumo stance with toes out and the bar over your midfoot, gripping inside your knees.',
        'Push your hips toward the bar, spread the floor, and drive up to lockout, then lower.',
      ],
      formChecks: [
        'Take a wide stance, toes out',
        'Grip inside your knees',
        'Spread the floor with your feet',
        'Push your hips through to lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BDK48n9IWww',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Sumo_Deadlift/0.jpg',
    ),
    'Rickshaw_Deadlift': ExerciseCoaching(
      howTo: [
        'Stand centered inside a loaded rickshaw frame with your feet hip width apart.',
        'Bend at the hips and knees to grip the handles at your sides, chest up and arms straight.',
        'Drive through your legs and extend your hips to stand tall with the frame, then lower under control.',
      ],
      formChecks: [
        'Grip the handles at your sides',
        'Drive through your legs to stand tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WMupZw3V1LE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rickshaw_Deadlift/0.jpg',
    ),
    'Romanian_Deadlift': ExerciseCoaching(
      howTo: [
        'Hold the bar at hip height with an overhand grip just wider than the shoulders, knees soft and shins vertical.',
        'Push the hips back to lower the bar down the front of the legs with a flat back until you feel a hamstring stretch, then drive the hips forward to stand tall.',
      ],
      formChecks: [
        'Back and arms stay straight',
        'Move steady, not fast',
        'Chest up, bar close to the legs',
        'Slight knee bend only, this is a hinge not a squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7j-2w4-P14I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Romanian_Deadlift/0.jpg',
    ),
    'Romanian_Deadlift_from_Deficit': ExerciseCoaching(
      howTo: [
        'Stand on a raised platform holding a barbell at your thighs with knees slightly bent.',
        'Push your hips back and lower the bar down your legs, letting it travel below foot level for extra range.',
        'Drive your hips forward to stand once you feel the hamstrings load.',
      ],
      formChecks: [
        'Push your hips back, not down',
        'Slide the bar down your thighs',
        'Sink into a deep hamstring stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hKA75HIYHpk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Romanian_Deadlift_from_Deficit/0.jpg',
    ),
    'Seated_Good_Mornings': ExerciseCoaching(
      howTo: [
        'Sit on a box set in a power rack with the bar across your rear delts, not your neck.',
        'Squeeze your shoulder blades together and brace your core.',
        'Bend forward at the waist, lowering your chest toward your thighs with a flat back, then contract to raise your torso upright.',
      ],
      formChecks: [
        'Set the bar across your rear delts',
        'Lower your chest toward your thighs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=t-xqLPZn2ts',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Good_Mornings/0.jpg',
    ),
    'Single_Leg_Glute_Bridge': ExerciseCoaching(
      howTo: [
        'Lie on your back with feet flat and knees bent, then lift one knee toward your chest.',
        'Drive through the heel of your planted foot and extend your hip to raise your hips off the floor until your body forms a straight line.',
        'Lower under control to the floor.',
      ],
      formChecks: [
        'Drive through your planted heel',
        'Keep both hips level as you rise',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sVfp4LN9niA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Leg_Glute_Bridge/0.jpg',
    ),
    'Snatch_Deadlift': ExerciseCoaching(
      howTo: [
        'Take a wide snatch grip on a barbell with your feet under your hips, toes turned out.',
        'Squat down to the bar with a flat back, chest up, and shoulders over the bar.',
        'Drive through the floor and extend your knees and hips, keeping the bar close as it travels up your legs.',
      ],
      formChecks: [
        'Take a wide snatch grip',
        'Set shoulders over the bar',
        'Keep chest up, back flat',
        'Sweep the bar close to your legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=L4imM4g2PT8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Deadlift/0.jpg',
    ),
    'Stiff_Leg_Barbell_Good_Morning': ExerciseCoaching(
      howTo: [
        'Set the bar across the back of your shoulders in a squat rack and step out.',
        'With only a slight bend in your knees, push your hips back and lower your torso toward the floor, keeping your back flat.',
        'Rise by extending your hips until you stand fully upright.',
      ],
      formChecks: [
        'Keep just a slight knee bend',
        'Hinge until your torso nears parallel',
        'Keep your back flat, not rounded',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jEO0blrPr9E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stiff_Leg_Barbell_Good_Morning/0.jpg',
    ),
    'Stiff-Legged_Barbell_Deadlift': ExerciseCoaching(
      howTo: [
        'With soft knees, hinge at the hips and lower the bar down the front of the legs, keeping the back flat until you feel a hamstring stretch.',
        'Drive the hips forward to stand tall.',
      ],
      formChecks: [
        'Hinge from the hips, minimal knee bend',
        'Back stays flat throughout',
        'Bar close to the legs the whole way',
        'Feel the stretch in the hamstrings, not the lower back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UWJcSIENXfQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stiff-Legged_Barbell_Deadlift/0.jpg',
    ),
    'Sumo_Deadlift_with_Bands': ExerciseCoaching(
      howTo: [
        'Loop bands over the bar and stand on them with a wide sumo stance, toes turned out.',
        'Grip inside your knees, chest up, hips back.',
        'Drive through your heels and push your hips to the bar to stand tall against the band tension, then lower under control.',
      ],
      formChecks: [
        'Toes out, grip inside your knees',
        'Spread the floor with your feet',
        'Snap your hips to the bar',
        'Accelerate against the bands',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dhJQFZ1wB0E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sumo_Deadlift_with_Bands/0.jpg',
    ),
    'Sumo_Deadlift_with_Chains': ExerciseCoaching(
      howTo: [
        'Drape chains over the barbell so more links lift off the floor as you rise.',
        'Set a wide sumo stance with toes out and grip the bar inside your knees.',
        'Brace, drive your feet down and stand tall as the chain load builds, then lower under control.',
      ],
      formChecks: [
        'Toes out, grip inside your knees',
        'Keep the chains off the plates',
        'Keep driving as links lift',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_i8tq5NihcE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sumo_Deadlift_with_Chains/0.jpg',
    ),
    'Trap_Bar_Deadlift': ExerciseCoaching(
      howTo: [
        'Stand in the center of a loaded trap bar and grip both handles.',
        'Lower your hips, lift your chest and look forward with a flat back.',
        'Push your feet through the floor to stand tall, driving with your legs, then hinge back down under control.',
      ],
      formChecks: [
        'Stand centered in the bar',
        'Push the floor away with your legs',
        'Drive the knees, not just hips',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=v709aJKv-gM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Trap_Bar_Deadlift/0.jpg',
    ),
    'Weighted_Ball_Hyperextension': ExerciseCoaching(
      howTo: [
        'Lie face down over an exercise ball with your torso parallel to the floor and the balls of your feet planted for balance.',
        'Hold a weight plate under your chin.',
        'Round down over the ball, then extend your spine to lift your chest until your body is straight.',
      ],
      formChecks: [
        'Plant the balls of your feet',
        'Extend up, don\'t overarch the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=r3e07nBGtzU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Ball_Hyperextension/0.jpg',
    ),
    'Wide_Stance_Stiff_Legs': ExerciseCoaching(
      howTo: [
        'Set a wide stance over a loaded barbell and hinge at the hips to grip it, legs nearly straight.',
        'Keep your back flat, chest up and hips pushed far back.',
        'Stand tall by driving your hips forward, feeling the hamstrings stretch, then hinge back down.',
      ],
      formChecks: [
        'Keep your legs nearly straight',
        'Push your hips back, not down',
        'Feel the hamstrings lengthen',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dfJj54mwR2g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide_Stance_Stiff_Legs/0.jpg',
    ),
    'Alternating_Kettlebell_Row': ExerciseCoaching(
      howTo: [
        'Set two kettlebells in front of your feet.',
        'Bend your knees slightly, push your hips back and grab both handles with a flat back.',
        'Row one kettlebell to your hip while the other stays down, lower it, then row the other side, alternating each rep.',
      ],
      formChecks: [
        'Hinge back, keep your back flat',
        'Row one bell at a time',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YTJw0Ko3tcg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Kettlebell_Row/0.jpg',
    ),
    'Alternating_Renegade_Row': ExerciseCoaching(
      howTo: [
        'Grip two kettlebells on the floor at shoulder width and set up in a pushup plank on the handles, body straight.',
        'Brace your core and row one kettlebell to your hip while balancing on the other.',
        'Lower it under control, then row the opposite side.',
      ],
      formChecks: [
        'Row without rotating your hips',
        'Hold a rigid plank throughout',
        'Widen your feet for a stable base',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=87fIdMr0Ojs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Renegade_Row/0.jpg',
    ),
    'Barbell_Rear_Delt_Row': ExerciseCoaching(
      howTo: [
        'Hold a barbell with a wide overhand grip and hinge forward, keeping the natural arch in your back and knees slightly bent.',
        'Let the bar hang at arm\'s length.',
        'Row it up toward your chest with elbows flaring wide, squeezing the rear delts, then lower slowly.',
      ],
      formChecks: [
        'Flare your elbows out wide',
        'Pull to your upper chest',
        'No heaving with the torso',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=PkhN_YyoWLI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Rear_Delt_Row/0.jpg',
    ),
    'Bent_Over_One-Arm_Long_Bar_Row': ExerciseCoaching(
      howTo: [
        'Wedge one end of a barbell into a corner and load the other end.',
        'Straddle the bar, hinge forward with a flat back and grip the loaded end with one hand.',
        'Row it up to your torso, driving your elbow back, then lower under control and switch sides.',
      ],
      formChecks: [
        'Wedge the far end securely',
        'Drive your elbow past your ribs',
        'Keep your hips level',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IHlkbFF4_e8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_One-Arm_Long_Bar_Row/0.jpg',
    ),
    'Bent_Over_Two-Arm_Long_Bar_Row': ExerciseCoaching(
      howTo: [
        'Wedge one end of a barbell into a corner and load the other end.',
        'Straddle the bar and hinge forward with a flat back, gripping the loaded end with both hands.',
        'Row the weight up to your chest, squeezing your shoulder blades, then lower under control.',
      ],
      formChecks: [
        'Straddle the bar and hinge flat',
        'Pull the loaded end to your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=I1glnib6U6g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Two-Arm_Long_Bar_Row/0.jpg',
    ),
    'Bent_Over_Two-Dumbbell_Row': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell in each hand and hinge forward at the waist, knees slightly bent, back flat until your torso is almost parallel to the floor.',
        'Let the dumbbells hang at arm\'s length.',
        'Row them up to your sides, squeezing your back, then lower under control.',
      ],
      formChecks: [
        'Hinge to near parallel, back flat',
        'Row the bells up to your sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6gvmcqr226U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Two-Dumbbell_Row/0.jpg',
    ),
    'Bent_Over_Two-Dumbbell_Row_With_Palms_In': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell in each hand with palms facing each other.',
        'Hinge forward at the waist with knees soft and back flat until your torso is near parallel to the floor.',
        'Row both dumbbells up along your sides, keeping the neutral grip, then lower under control.',
      ],
      formChecks: [
        'Keep your palms facing each other',
        'Drive elbows back along your sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=s84h7wXzOQ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Two-Dumbbell_Row_With_Palms_In/0.jpg',
    ),
    'Bodyweight_Mid_Row': ExerciseCoaching(
      howTo: [
        'Take a medium to wide overhand grip on a pull-up bar and hang.',
        'Tuck your knees to your chest and lean back, bringing your legs up over the bar so your body is horizontal beneath it.',
        'Pull your chest up to the bar, then lower back down under control.',
      ],
      formChecks: [
        'Get your body horizontal under the bar',
        'Stay rigid, no sagging hips',
        'Pull your chest to the bar',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7xMrD4x5WaU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Mid_Row/0.jpg',
    ),
    'Cable_Rope_Rear-Delt_Rows': ExerciseCoaching(
      howTo: [
        'Sit at a low pulley row station and attach a rope, gripping it overhand with arms extended parallel to the floor.',
        'Keeping your upper arms high, pull the rope toward your face and flare your elbows out wide to hit the rear delts.',
        'Return under control.',
      ],
      formChecks: [
        'Keep your upper arms high',
        'Pull the rope toward your face',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=k06dvb79nR8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Rope_Rear-Delt_Rows/0.jpg',
    ),
    'Dumbbell_Incline_Row': ExerciseCoaching(
      howTo: [
        'Set an incline bench and lie chest-down against it with a dumbbell in each hand, neutral grip, arms hanging straight.',
        'Squeeze your shoulder blades and row both dumbbells up by driving your elbows back.',
        'Squeeze at the top, then lower under control.',
      ],
      formChecks: [
        'Keep your chest on the bench',
        'Squeeze your shoulder blades first',
        'Drive the elbows back and up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1shmqxxx-fQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Incline_Row/0.jpg',
    ),
    'Dumbbell_One-Arm_Upright_Row': ExerciseCoaching(
      howTo: [
        'Stand tall holding a dumbbell in front of your thigh with your arm straight.',
        'Pull it straight up along your body toward your chin, leading with your elbow until it rises above your wrist.',
        'Lower it slowly back to your thigh.',
      ],
      formChecks: [
        'Lead with the elbow',
        'Raise the elbow above the wrist',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VtCGdQti7c0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_One-Arm_Upright_Row/0.jpg',
    ),
    'Elevated_Cable_Rows': ExerciseCoaching(
      howTo: [
        'Place a low platform on the seat of a cable row machine and sit on it so you are elevated, feet on the front crossbar.',
        'Grab the handle with your arms extended, then pull it into your torso, driving your elbows back and squeezing your lats.',
        'Return slowly to a full stretch.',
      ],
      formChecks: [
        'Reach forward for a deep stretch',
        'Pull the handle to your stomach',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3GEkyB9Ke2w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elevated_Cable_Rows/0.jpg',
    ),
    'Face_Pull': ExerciseCoaching(
      howTo: [
        'Set a rope on a high pulley and grab both ends with palms facing in.',
        'Pull the rope toward your face, separating your hands and flaring your elbows out until your hands reach your ears.',
        'Keep your upper arms parallel to the floor and lower under control.',
      ],
      formChecks: [
        'Pull the rope to your forehead',
        'Flare your elbows up and out',
        'Split your hands at the finish',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=w-RctWbFNGc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Face_Pull/0.jpg',
    ),
    'Gironda_Sternum_Chins': ExerciseCoaching(
      howTo: [
        'Grip the bar with a shoulder-width underhand hold and hang with your chest up and body leaning back.',
        'Pull yourself up while leaning back further, tucking your head back until your lower chest meets the bar.',
        'Lower under control to a full hang.',
      ],
      formChecks: [
        'Lean back more as you climb',
        'Tuck your head back',
        'Touch the bar to your lower chest',
        'Keep your chest up and arched',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xJ4Yh7KiT2g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Gironda_Sternum_Chins/0.jpg',
    ),
    'Inverted_Row': ExerciseCoaching(
      howTo: [
        'Set a bar in a rack at about waist height and hang underneath it with a wider than shoulder-width grip.',
        'Keep your body straight from heels to head and pull your chest up to the bar, driving your elbows back.',
        'Lower yourself under control until your arms are straight.',
      ],
      formChecks: [
        'Hold a straight line heels to head',
        'Pull your chest to the bar',
        'Drive your elbows back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KOaCM1HMwU0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'Inverted_Row_with_Straps': ExerciseCoaching(
      howTo: [
        'Hang suspension straps from a rack and grab a handle in each hand, positioning yourself face-up with arms extended.',
        'Keep your body straight with heels on the floor and pull your chest toward your hands, driving your elbows down and back.',
        'Lower slowly to full arm extension.',
      ],
      formChecks: [
        'Stop your hips from sagging',
        'Pull your chest to your hands',
        'Drive elbows down and back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0AsxBmXeOIo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row_with_Straps/0.jpg',
    ),
    'Kettlebell_Sumo_High_Pull': ExerciseCoaching(
      howTo: [
        'Stand in a wide sumo stance with a kettlebell between your feet and grip it with both hands, hips set back and chest up.',
        'Drive through your legs and hips to pull the kettlebell explosively up to chest height, leading with high elbows.',
        'Lower it back between your legs.',
      ],
      formChecks: [
        'Drive through legs and hips',
        'Explode the bell to chest height',
        'Lead with high elbows',
        'Keep your chest up, back flat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HnAzcuwSO8g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Sumo_High_Pull/0.jpg',
    ),
    'Kneeling_High_Pulley_Row': ExerciseCoaching(
      howTo: [
        'Attach a rope to a high pulley and kneel a couple of feet back, holding both ends with your arms extended toward the pulley.',
        'Pull the rope down and toward your forehead, driving your elbows down and back as you squeeze your lats.',
        'Return under control to full extension.',
      ],
      formChecks: [
        'Drive elbows down and back',
        'Keep your torso upright',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9JaHBN3_Wzo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_High_Pulley_Row/0.jpg',
    ),
    'Kneeling_Single-Arm_High_Pulley_Row': ExerciseCoaching(
      howTo: [
        'Attach a single handle to a high pulley and kneel in front of it, taking the handle in one hand with your arm extended overhead and palm facing forward.',
        'Pull the handle down and back toward your ribs, driving your elbow down as you squeeze the lat.',
        'Return slowly to full stretch.',
      ],
      formChecks: [
        'Reach overhead for a full stretch',
        'Pull your elbow to your ribs',
        'Stop your torso twisting',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=s0JmKATyCUs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Single-Arm_High_Pulley_Row/0.jpg',
    ),
    'Leverage_High_Row': ExerciseCoaching(
      howTo: [
        'Adjust the seat so you can just reach the overhead handles and lock your knees under the pad.',
        'Grab the handles with a overhand grip, arms extended above you, then pull them down and back toward your torso, driving your elbows down and squeezing your back.',
        'Return under control.',
      ],
      formChecks: [
        'Pull the handles to your torso',
        'Stay pinned under the knee pad',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=TpN5JkNVKxA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_High_Row/0.jpg',
    ),
    'Leverage_Iso_Row': ExerciseCoaching(
      howTo: [
        'Adjust the seat so the handles sit at chest level and grip them with a neutral or overhand hold, chest against the pad.',
        'Pull the handles back toward your torso, driving your elbows behind you and squeezing your lats.',
        'Return slowly until your arms are fully extended.',
      ],
      formChecks: [
        'Keep your chest on the pad',
        'Drive elbows straight back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QEo_m-WTaUs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Iso_Row/0.jpg',
    ),
    'London_Bridges': ExerciseCoaching(
      howTo: [
        'Anchor a climbing rope overhead and stand on a locked bar or box, gripping the rope with both hands.',
        'Lean back and lower your body by extending your arms while keeping your feet planted.',
        'Pull yourself back upright by driving your elbows down and squeezing your lats.',
      ],
      formChecks: [
        'Stay rigid as you lean back',
        'Keep your feet planted',
        'Pull up by driving elbows down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aqz4QMKlqNU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/London_Bridges/0.jpg',
    ),
    'Low_Pulley_Row_To_Neck': ExerciseCoaching(
      howTo: [
        'Sit at a low pulley with a rope attachment and hold the ends with a palms-down grip, back upright and arms extended.',
        'Pull the rope up toward your neck, flaring your elbows out high and separating your hands.',
        'Return under control to full arm extension.',
      ],
      formChecks: [
        'Pull the rope up to your neck',
        'Keep elbows high and wide',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XyCyNKOH6Ew',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Low_Pulley_Row_To_Neck/0.jpg',
    ),
    'Lying_Cambered_Barbell_Row': ExerciseCoaching(
      howTo: [
        'Lie face down on a bench with a cambered barbell on the floor beneath you and grab it with a wide overhand grip.',
        'Row the bar up toward the underside of the bench, driving your elbows back and squeezing your shoulder blades.',
        'Lower it under control to full extension.',
      ],
      formChecks: [
        'Keep your chest on the bench',
        'Row the bar up to the bench',
        'No jerking or heaving',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QWsHaMO86OY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Cambered_Barbell_Row/0.jpg',
    ),
    'Lying_T-Bar_Row': ExerciseCoaching(
      howTo: [
        'Set the machine so your upper chest rests at the top of the pad, then grab the handles and let your arms hang extended.',
        'Row the weight up by driving your elbows back and squeezing your shoulder blades together.',
        'Lower it slowly to a full stretch.',
      ],
      formChecks: [
        'Pin your chest to the pad',
        'Drive elbows back and up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EOFZfYZYAO8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_T-Bar_Row/0.jpg',
    ),
    'Mixed_Grip_Chin': ExerciseCoaching(
      howTo: [
        'Grab a pull-up bar just wider than shoulder width with one palm facing you and one facing away, hanging with arms fully extended.',
        'Pull your chest toward the bar until your chin clears it, driving your elbows down.',
        'Lower under control to a full hang.',
      ],
      formChecks: [
        'Set one palm toward you, one away',
        'Drive elbows down to clear the bar',
        'Swap grip each set',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xjME35NboRA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Mixed_Grip_Chin/0.jpg',
    ),
    'One-Arm_Dumbbell_Row': ExerciseCoaching(
      howTo: [
        'With one hand and knee on a bench and a flat back, let the dumbbell hang.',
        'Row it to the hip by driving the elbow up and back, then lower to a full stretch.',
      ],
      formChecks: [
        'Keep the back flat and steady',
        'Row to the hip, elbow close to the body',
        'Squeeze the back at the top',
        'Don\'t rotate the torso to lift',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ZRSGpBUVcNw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Dumbbell_Row/0.jpg',
    ),
    'One-Arm_Long_Bar_Row': ExerciseCoaching(
      howTo: [
        'Wedge a barbell into a landmine and load the working end, then stand beside the bar and grab it just behind the collar with one hand.',
        'Hinge at the hips with a flat back and let the arm hang.',
        'Pull the bar up toward your hip, then lower until your arm straightens.',
      ],
      formChecks: [
        'Hinge with a flat back',
        'Row to your hip without twisting',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Zm46P2zM_-0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Long_Bar_Row/0.jpg',
    ),
    'Reverse_Grip_Bent-Over_Rows': ExerciseCoaching(
      howTo: [
        'Hinge to near-parallel with an underhand grip and flat back.',
        'Pull the bar to the lower abdomen by driving the elbows back, then lower under control.',
      ],
      formChecks: [
        'Underhand grip hits the lower lats',
        'Keep the torso fixed and back flat',
        'Drive the elbows past the ribs',
        'Control the bar down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pPJWtsTJmkY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Grip_Bent-Over_Rows/0.jpg',
    ),
    'Rope_Climb': ExerciseCoaching(
      howTo: [
        'Grip the rope overhead with both hands, then pull down hard as you jump and wrap the rope around one leg, pinching it between your feet.',
        'Reach up and re-grip as high as you can, pull yourself up, and lock the rope again with your feet.',
        'Climb hand over hand.',
      ],
      formChecks: [
        'Pinch the rope between your feet',
        'Reach high before each pull',
        'Pull with your back not just arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=qFE7pgOrj5w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Climb/0.jpg',
    ),
    'Rowing_Stationary': ExerciseCoaching(
      howTo: [
        'Sit on the rower, strap in your feet with your heels on the pedals, and slide forward into the catch with knees bent and shins vertical.',
        'Drive hard through your legs to push the seat back, then lean back and pull the handle to your ribs.',
        'Slide forward to reset.',
      ],
      formChecks: [
        'Start with shins vertical',
        'Drive legs, then lean, then pull',
        'Push heels through the pedals',
        'Return arms, body, then legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=I12TqJNQJsM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rowing_Stationary/0.jpg',
    ),
    'Seated_Cable_Rows': ExerciseCoaching(
      howTo: [
        'Sit tall with a slight knee bend and grip the handle.',
        'Pull to the lower ribs by driving the elbows back and squeezing the shoulder blades, then return to a full stretch without slumping.',
      ],
      formChecks: [
        'Chest up, pull to the lower ribs',
        'Drive the elbows back, squeeze the blades',
        'Don\'t heave with the lower back',
        'Control the stretch at the front',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UCXxvVItLoM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Cable_Rows/0.jpg',
    ),
    'Seated_One-arm_Cable_Pulley_Rows': ExerciseCoaching(
      howTo: [
        'Sit at a low cable station with your feet braced and knees slightly bent, then take a single handle in one hand and reach forward so your shoulder stretches.',
        'Pull the handle to your waist, driving your elbow back and squeezing your shoulder blade.',
        'Extend to reset.',
      ],
      formChecks: [
        'Reach forward for a full stretch',
        'Drive your elbow to your waist',
        'Keep your torso still',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dL3_oLhO8y0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_One-arm_Cable_Pulley_Rows/0.jpg',
    ),
    'Shotgun_Row': ExerciseCoaching(
      howTo: [
        'Attach a single handle to a low cable and grab it with one hand, then step back into a split stance until the cable is tight, arm extended and shoulder forward.',
        'Pull the handle to your ribs while rotating your torso slightly outward.',
        'Extend your arm to reset.',
      ],
      formChecks: [
        'Split stance, cable pulled tight',
        'Rotate your torso out as you pull',
        'Reach your shoulder forward at the start',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zVNSVxv8M8A',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Shotgun_Row/0.jpg',
    ),
    'Side_To_Side_Chins': ExerciseCoaching(
      howTo: [
        'Grab a pull-up bar with a wide overhand grip and hang with arms extended.',
        'Pull yourself up toward your left hand until your chin nears it, then lower under control.',
        'Pull up toward your right hand, alternating sides on each rep.',
      ],
      formChecks: [
        'Pull up toward one hand',
        'Alternate sides each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hIMOyFQ7P0g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_To_Side_Chins/0.jpg',
    ),
    'Sled_Row': ExerciseCoaching(
      howTo: [
        'Attach two handles to a loaded sled and face it, backing up until the rope pulls tight with a handle in each hand and knees slightly bent.',
        'Keep your chest up and row both handles to your ribs, driving your elbows back.',
        'Step back to reset the tension.',
      ],
      formChecks: [
        'Row both handles to your ribs',
        'Keep your chest up as you pull',
        'Step back to reset the rope',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sKz1Op4Tph0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Row/0.jpg',
    ),
    'Smith_Machine_Bent_Over_Row': ExerciseCoaching(
      howTo: [
        'Hold the bar with an overhand grip, soften the knees and hinge at the hips until the torso is near parallel with a flat back.',
        'Pull the bar to the lower ribs by driving the elbows back, squeeze the shoulder blades, then lower under control.',
      ],
      formChecks: [
        'Torso stays fixed, only the arms move',
        'Lead with the elbows',
        'Squeeze the back at the top',
        'Keep the head neutral and back flat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1KTusMnNGgo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Bent_Over_Row/0.jpg',
    ),
    'Smith_Machine_Upright_Row': ExerciseCoaching(
      howTo: [
        'Set the Smith bar at mid-thigh height and grip it shoulder width with an overhand grip, then unrack and stand tall with arms extended.',
        'Pull the bar straight up along your body to chest height, leading with your elbows.',
        'Lower it back down under control.',
      ],
      formChecks: [
        'Lead with high elbows',
        'Stop at chest height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QIpa-9dtkgA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Upright_Row/0.jpg',
    ),
    'Standing_Dumbbell_Upright_Row': ExerciseCoaching(
      howTo: [
        'Hold the dumbbells in front of the thighs.',
        'Pull them straight up along the body by leading with the elbows to about chest height, then lower under control.',
      ],
      formChecks: [
        'Lead with the elbows, keep the weights close',
        'Don\'t pull above chest height',
        'Control the descent',
        'Stop if the shoulders pinch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Rd5AsxOGqss',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Upright_Row/0.jpg',
    ),
    'Straight_Bar_Bench_Mid_Rows': ExerciseCoaching(
      howTo: [
        'Place a loaded barbell on the end of a bench and stand on the bench behind it, hinging down to take a medium overhand grip.',
        'Set your hips back and chest up with a neutral spine.',
        'Pull the bar to your lower chest, squeeze your back, then lower to a stretch.',
      ],
      formChecks: [
        'Stand tall on the bench',
        'Pull the bar to your lower chest',
        'Let it stretch at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=qXrTDQG1oUQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight_Bar_Bench_Mid_Rows/0.jpg',
    ),
    'Suspended_Row': ExerciseCoaching(
      howTo: [
        'Set suspension straps at chest height, take a handle in each hand, and lean back with arms extended, body straight from head to heels.',
        'Pull your chest up to your hands by driving your elbows back and squeezing your shoulder blades.',
        'Lower until your arms straighten.',
      ],
      formChecks: [
        'Hold a straight line head to heels',
        'Pull your chest to the handles',
        'Don\'t let your hips sag',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=X9ptLAm8fuE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Row/0.jpg',
    ),
    'T-Bar_Row_with_Handle': ExerciseCoaching(
      howTo: [
        'Wedge a barbell into a landmine and load the working end, then straddle the bar and loop a double-D handle around it near the collar.',
        'Hinge at the hips with a flat back and chest up, arms extended.',
        'Pull the handle to your chest, squeeze your back, then lower to a stretch.',
      ],
      formChecks: [
        'Straddle the bar and hinge over',
        'Keep a flat back, chest up',
        'Pull the handle to your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KDEl3AmZbVE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/T-Bar_Row_with_Handle/0.jpg',
    ),
    'Two-Arm_Kettlebell_Row': ExerciseCoaching(
      howTo: [
        'Set two kettlebells just in front of your feet, then bend your knees slightly and push your hips back to hinge over with a flat back.',
        'Grab both handles and pull them to your stomach, squeeze your shoulder blades.',
        'Lower them until your arms are straight.',
      ],
      formChecks: [
        'Hinge, don\'t round your back',
        'Pull both bells to your stomach',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Z-h9oOqpyu8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Row/0.jpg',
    ),
    'Upright_Barbell_Row': ExerciseCoaching(
      howTo: [
        'Grip a barbell with an overhand grip slightly narrower than shoulder width, arms hanging so the bar rests on your thighs and your back straight.',
        'Pull the bar straight up along your body toward your collarbone, leading with your elbows.',
        'Lower it under control.',
      ],
      formChecks: [
        'Lead with your elbows',
        'Pull to your collarbone, no swing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nIJGvsdNtFE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Upright_Barbell_Row/0.jpg',
    ),
    'Alternating_Floor_Press': ExerciseCoaching(
      howTo: [
        'Lie on your back with a kettlebell racked at each shoulder, palms facing forward and elbows on the floor.',
        'Press one kettlebell straight up until your arm locks out, then lower it back to the floor.',
        'Press the other side, alternating arms each rep.',
      ],
      formChecks: [
        'Pause as your elbow taps the floor',
        'Press one arm at a time',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=e4StK2BoQIE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Floor_Press/0.jpg',
    ),
    'Around_The_Worlds': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench holding a dumbbell in each hand at your thighs, palms up and elbows slightly bent.',
        'Sweep both dumbbells out and up in a wide arc until they nearly meet above your head.',
        'Trace the same circular path back down to your thighs.',
      ],
      formChecks: [
        'Hold a soft elbow bend',
        'Sweep wide and stay light',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=w_Pplr0hI1s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Around_The_Worlds/0.jpg',
    ),
    'Barbell_Bench_Press_-_Medium_Grip': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and take a grip that puts the forearms vertical at the bottom.',
        'Unrack and hold the bar over the chest with locked arms.',
        'Lower under control until it touches mid-chest, pause, then press back up and squeeze the chest at the top.',
      ],
      formChecks: [
        'Forearms roughly vertical at the bottom',
        'Lower about twice as slowly as you press',
        'Drive from the chest',
        'Keep the wrists stacked over the elbows',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lJ2o89kcnxY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Bench_Press_-_Medium_Grip/0.jpg',
    ),
    'Barbell_Guillotine_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and take a medium-wide grip on the bar.',
        'Unrack it and hold it over your neck with arms locked.',
        'Lower the bar slowly toward your neck with elbows flared out, then press it back up to full lockout.',
      ],
      formChecks: [
        'Use a lighter weight',
        'Flare elbows out wide',
        'Lower toward your neck',
        'Keep a spotter ready',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7wO4DG1mshs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Guillotine_Bench_Press/0.jpg',
    ),
    'Barbell_Incline_Bench_Press_-_Medium_Grip': ExerciseCoaching(
      howTo: [
        'Lie back on an incline bench and grip the bar at medium width.',
        'Unrack it and hold it straight over your upper chest with arms locked.',
        'Lower the bar slowly to your upper chest, then drive it back up until your arms lock out.',
      ],
      formChecks: [
        'Grip at medium width',
        'Lower to your upper chest',
        'Keep shoulder blades pinned',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UFPZPkF1PDY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Incline_Bench_Press_-_Medium_Grip/0.jpg',
    ),
    'Bench_Press_-_Powerlifting': ExerciseCoaching(
      howTo: [
        'Lie on the bench with your eyes under the bar, plant your feet, and arch your back with shoulder blades squeezed together.',
        'Unrack the bar over your chest.',
        'Lower it under control to your lower chest with elbows tucked, then press up to lockout.',
      ],
      formChecks: [
        'Arch and pin your shoulder blades',
        'Tuck elbows going down',
        'Touch your lower chest',
        'Drive through the legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SCVCLChPQFY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Press_-_Powerlifting/0.jpg',
    ),
    'Bench_Press_with_Chains': ExerciseCoaching(
      howTo: [
        'Drape the chains over the bar sleeves and lie on the bench with your eyes under the bar.',
        'Set your feet, arch, and squeeze your shoulder blades.',
        'Unrack the bar, lower it to your chest as the chains pool on the floor, then press up as they rise.',
      ],
      formChecks: [
        'Tuck elbows lowering the bar',
        'Let chains pool at the bottom',
        'Explode as the chains rise',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KhnIvtUr8Qw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Press_with_Chains/0.jpg',
    ),
    'Board_Press': ExerciseCoaching(
      howTo: [
        'Have a partner hold a stack of boards on your chest.',
        'Lie on the bench with feet planted, back arched, and shoulder blades pulled together.',
        'Unrack the bar, lower it under control until it touches the boards, then press back up to full lockout.',
      ],
      formChecks: [
        'Touch boards without bouncing',
        'Drive hard off the boards',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=iIBp-my013I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Board_Press/0.jpg',
    ),
    'Cable_Chest_Press': ExerciseCoaching(
      howTo: [
        'Sit at the cable station and grab a handle in each hand with your upper arms about 45 degrees from your body and elbows bent.',
        'Keep your chest up and press the handles forward until your arms extend.',
        'Bring them back slowly until your chest stretches.',
      ],
      formChecks: [
        'Keep chest tall, shoulders back',
        'Press out, fight the cable back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sh92B-_2O48',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Chest_Press/0.jpg',
    ),
    'Chain_Press': ExerciseCoaching(
      howTo: [
        'Attach handles to the chains and lie back on a flat bench holding one in each hand.',
        'Position your wrists palms-down with the load at chest level and arms perpendicular to the floor.',
        'Press the chains straight up to lockout, then lower them to your chest.',
      ],
      formChecks: [
        'Keep your wrists palms-down',
        'Press straight up',
        'Steady the swinging chains',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8YYHWMNRhlk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chain_Press/0.jpg',
    ),
    'Close-Grip_Barbell_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie back on a flat bench and grip the bar at about shoulder width.',
        'Unrack it and hold it over your chest with arms locked.',
        'Lower the bar slowly to your lower chest with elbows tucked close to your sides, then press it back up until your arms lock out.',
      ],
      formChecks: [
        'Grip about shoulder width',
        'Tuck elbows to your sides',
        'Push through your triceps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DzA2xZhDGeo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Barbell_Bench_Press/0.jpg',
    ),
    'Cross_Over_-_With_Bands': ExerciseCoaching(
      howTo: [
        'Anchor a band to a post and face away, holding a handle in each hand with arms out to your sides at shoulder height.',
        'Step forward to create tension.',
        'Bring your hands together in a wide arc in front of your chest, then return slowly to the stretch.',
      ],
      formChecks: [
        'Keep a soft elbow bend',
        'Squeeze as hands cross',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8G8C8f8Zo8A',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cross_Over_-_With_Bands/0.jpg',
    ),
    'Decline_Barbell_Bench_Press': ExerciseCoaching(
      howTo: [
        'On a decline bench with feet secured, unrack and hold the bar over the lower chest.',
        'Lower under control to the lower chest, then press back up and lock out.',
      ],
      formChecks: [
        'Bar tracks to the lower chest',
        'Keep the shoulder blades squeezed',
        'Control down, drive up',
        'Keep the wrists stacked over the elbows',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IqXtJnai1ik',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Barbell_Bench_Press/0.jpg',
    ),
    'Decline_Dumbbell_Flyes': ExerciseCoaching(
      howTo: [
        'Secure your legs on a decline bench and lie back with a dumbbell in each hand over your chest, palms facing each other and elbows slightly bent.',
        'Lower the dumbbells out to your sides in a wide arc until your chest stretches, then bring them back together.',
      ],
      formChecks: [
        'Lock a fixed elbow bend',
        'Open wide to a deep stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5AaHLf-VZv8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Dumbbell_Flyes/0.jpg',
    ),
    'Decline_Smith_Press': ExerciseCoaching(
      howTo: [
        'Set a decline bench in a Smith machine and lie back so the bar sits over your lower chest.',
        'Take a overhand grip wider than shoulder width and unlock the bar.',
        'Lower it under control to your lower chest, then press it straight up and lock out.',
      ],
      formChecks: [
        'Grip wider than shoulders',
        'Lower to your lower chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AvHhETF8fWA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Smith_Press/0.jpg',
    ),
    'Dumbbell_Bench_Press_with_Neutral_Grip': ExerciseCoaching(
      howTo: [
        'Lie flat holding the dumbbells over the chest with palms facing each other.',
        'Lower to the sides of the chest, then press up and slightly together.',
      ],
      formChecks: [
        'Neutral grip is easier on the shoulders',
        'Shoulder blades pinned back and down',
        'Lower to a controlled stretch',
        'Keep the dumbbells stacked over the elbows',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fZuQpjhaR_M',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Bench_Press_with_Neutral_Grip/0.jpg',
    ),
    'Extended_Range_One-Arm_Kettlebell_Floor_Press': ExerciseCoaching(
      howTo: [
        'Lie on the floor holding a kettlebell by the handle in one hand at your chest.',
        'Bend the knee on the same side and cross it over your body midline to open the shoulder.',
        'Press the kettlebell straight up to lockout, then lower it deep for a full stretch.',
      ],
      formChecks: [
        'Cross the same-side knee over',
        'Stack your wrist over elbow',
        'Press straight up',
        'Lower deep for a big stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=p_pf8S5vpTU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Extended_Range_One-Arm_Kettlebell_Floor_Press/0.jpg',
    ),
    'Floor_Press': ExerciseCoaching(
      howTo: [
        'Lie on the floor under a power rack with the bar set on the j-hooks above your chest.',
        'Pull your shoulder blades together and take the bar off the hooks.',
        'Lower it until your upper arms rest on the floor, pause, then press back up to lockout.',
      ],
      formChecks: [
        'Touch upper arms to the floor',
        'Pause on the floor',
        'Drive up from the dead stop',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=T0Y3OBF1bNI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Floor_Press/0.jpg',
    ),
    'Floor_Press_with_Chains': ExerciseCoaching(
      howTo: [
        'Drape the chains over the ends of the bar and lie on the floor under a power rack.',
        'Pull your shoulder blades together and unrack the bar over your chest.',
        'Lower it until your upper arms touch the floor, then press up hard as the chains lift and add load.',
      ],
      formChecks: [
        'Touch upper arms to the floor',
        'Pause at the bottom',
        'Keep elbows tucked in',
        'Explode as chains lift',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=TWh-OsE4UF0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Floor_Press_with_Chains/0.jpg',
    ),
    'Forward_Drag_with_Press': ExerciseCoaching(
      howTo: [
        'Attach two rope handles to a sled and face away with a handle at each side of your chest.',
        'Lean into it, drive through your legs to step forward, and press both handles straight out to drag the sled.',
        'Keep stepping and pressing to keep the sled moving.',
      ],
      formChecks: [
        'Lean into the sled',
        'Drive your legs to move it',
        'Press both ropes to lockout',
        'Press as you step',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Iu7xUQ-fZfw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Forward_Drag_with_Press/0.jpg',
    ),
    'Hammer_Grip_Incline_DB_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie back on an incline bench holding a dumbbell in each hand with palms facing each other.',
        'Press the dumbbells up over your chest until your arms are extended.',
        'Lower them slowly back to the sides of your chest, keeping the neutral grip throughout.',
      ],
      formChecks: [
        'Palms face each other',
        'Tuck elbows to your ribs',
        'Press over the upper chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=G4qnXn5BjhI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hammer_Grip_Incline_DB_Bench_Press/0.jpg',
    ),
    'Incline_Cable_Chest_Press': ExerciseCoaching(
      howTo: [
        'Sit at the cable station and grasp a handle in each hand with elbows bent about 90 degrees and upper arms at 45 degrees to your body.',
        'Press the handles forward and together until your arms are extended.',
        'Bring them back slowly until you feel a stretch across the chest.',
      ],
      formChecks: [
        'Chest up, head back',
        'Press the handles together',
        'Let the cables stretch you back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=K88hDCAfjMU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Cable_Chest_Press/0.jpg',
    ),
    'Incline_Dumbbell_Bench_With_Palms_Facing_In': ExerciseCoaching(
      howTo: [
        'Lie back on an incline bench with a dumbbell in each hand resting at the sides of your chest, palms facing in toward each other.',
        'Press both dumbbells straight up until your arms lock out over your upper chest.',
        'Lower them slowly back down the same path.',
      ],
      formChecks: [
        'Press straight up to lockout',
        'Lower to the sides of your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SQF1eEo6phU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Bench_With_Palms_Facing_In/0.jpg',
    ),
    'Incline_Dumbbell_Flyes': ExerciseCoaching(
      howTo: [
        'On an incline with the dumbbells above the chest and a slight elbow bend, open the arms out to the sides until you feel a chest stretch, then bring them back together in an arc.',
      ],
      formChecks: [
        'Fixed, slight elbow bend throughout',
        'Open until you feel a stretch, don\'t overdo it',
        'Hug the weights back together',
        'Keep the shoulder blades set',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JSDpq14vCZ8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Flyes/0.jpg',
    ),
    'Incline_Dumbbell_Flyes_-_With_A_Twist': ExerciseCoaching(
      howTo: [
        'Lie on an incline bench set no higher than 30 degrees, holding a dumbbell in each hand extended above your chest with a slight elbow bend.',
        'Open your arms wide in an arc until you feel a stretch across the chest.',
        'Squeeze them back up and rotate your wrists so palms face at the top.',
      ],
      formChecks: [
        'Keep a soft elbow bend',
        'Open wide in an arc, no press',
        'Twist the dumbbells up top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ssiFwHINCYk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Flyes_-_With_A_Twist/0.jpg',
    ),
    'Incline_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'On a 30-45 degree incline, start with the dumbbells at the upper chest, palms forward.',
        'Press up and slightly together until the arms are extended, then lower under control to a full stretch.',
      ],
      formChecks: [
        'Keep the shoulder blades pulled back and down',
        'Lower to a controlled stretch, don\'t bounce',
        'Elbows around 45 degrees, not flared to 90',
        'Press in a slight arc toward the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6tW4LUaOxlE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Dumbbell_Press/0.jpg',
    ),
    'Isometric_Wipers': ExerciseCoaching(
      howTo: [
        'Set up in a push-up position with your body straight and hands just outside shoulder width.',
        'Bend one arm to shift your weight as far over that hand as you can and hold there.',
        'Push back to center, then shift and hold over the other side.',
      ],
      formChecks: [
        'Shift fully onto one hand',
        'Hold without letting hips sag',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XtQ-Kx_1OVs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Wipers/0.jpg',
    ),
    'Leg-Over_Floor_Press': ExerciseCoaching(
      howTo: [
        'Lie on the floor holding a kettlebell at your chest by the handle, with your free arm out to the side for support.',
        'Cross the leg on your working side over the other leg.',
        'Press the kettlebell straight up to a locked-out arm, then lower it under control back to your chest.',
      ],
      formChecks: [
        'Cross the working-side leg over',
        'Press the bell to lockout',
        'Free arm braces the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rK6_eLYosrA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg-Over_Floor_Press/0.jpg',
    ),
    'Leverage_Chest_Press': ExerciseCoaching(
      howTo: [
        'Adjust the seat so the handles sit at the middle of your chest and grasp them with your chest up and shoulder blades pulled back.',
        'Press the handles forward until your arms are extended.',
        'Bring them back slowly until your hands return to chest level.',
      ],
      formChecks: [
        'Set handles at mid-chest',
        'Keep shoulder blades pinned back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=-YiqDRTu8ag',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Chest_Press/0.jpg',
    ),
    'Leverage_Decline_Chest_Press': ExerciseCoaching(
      howTo: [
        'Adjust the seat so the handles line up with the lower edge of your chest and grip them with your chest up and shoulder blades squeezed.',
        'Press the handles forward and slightly down until your arms extend.',
        'Return slowly to the lower-chest position.',
      ],
      formChecks: [
        'Line handles up with lower chest',
        'Press forward and slightly down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xK9zpXvjFUg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Decline_Chest_Press/0.jpg',
    ),
    'Leverage_Incline_Chest_Press': ExerciseCoaching(
      howTo: [
        'Adjust the seat so the handles align with the top of your chest and grasp them with your chest up and shoulder blades pulled back.',
        'Press the handles up and forward until your arms are extended.',
        'Lower them slowly back to the upper-chest position.',
      ],
      formChecks: [
        'Line handles up with upper chest',
        'Press up and forward',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ijOS9-7yIug',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Incline_Chest_Press/0.jpg',
    ),
    'Machine_Bench_Press': ExerciseCoaching(
      howTo: [
        'Set the seat so the handles line up with the mid-chest.',
        'Press the handles forward until the arms are extended, then return under control to a stretch.',
      ],
      formChecks: [
        'Adjust the seat so handles meet the mid-chest',
        'Keep the back against the pad',
        'Don\'t let the shoulders roll forward',
        'Control the return, don\'t let it slam',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sqNwDkUU_Ps',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Bench_Press/0.jpg',
    ),
    'Neck_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and take a medium grip on the bar, then lift it from the rack and hold it above your upper chest.',
        'Lower the bar slowly toward the base of your neck with your elbows flaring out.',
        'Press it back up until your arms are extended over the same spot.',
      ],
      formChecks: [
        'Use a light, controlled load',
        'Lower to your neckline',
        'Let your elbows flare wide',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HBh9sFfzPVM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Neck_Press/0.jpg',
    ),
    'One_Arm_Dumbbell_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench holding a single dumbbell at shoulder level with one hand, palm facing forward.',
        'Brace with your free arm for balance.',
        'Press the dumbbell straight up until your arm is extended, then lower it slowly back to the side of your chest.',
      ],
      formChecks: [
        'Resist twisting toward the weight',
        'Keep both hips flat on the bench',
        'Press straight up to lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gZLuQxfJhOY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Dumbbell_Bench_Press/0.jpg',
    ),
    'One_Arm_Floor_Press': ExerciseCoaching(
      howTo: [
        'Lie on your back on the floor with your knees bent and take the bar in one hand with your arm extended above your shoulder.',
        'Lower it by bending the elbow until your upper arm rests on the floor.',
        'Press the bar back up by driving through your triceps to full extension.',
      ],
      formChecks: [
        'Keep the elbow tracking close',
        'Pause when your arm hits the floor',
        'Drive up through the triceps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jUXUJxxBmjY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Floor_Press/0.jpg',
    ),
    'One-Arm_Kettlebell_Floor_Press': ExerciseCoaching(
      howTo: [
        'Lie on the floor holding a kettlebell in one hand with your upper arm resting on the floor and palm facing in.',
        'Press the kettlebell straight up toward the ceiling, rotating your wrist as it rises.',
        'Lower it slowly until your upper arm settles back to the floor.',
      ],
      formChecks: [
        'Start with palm facing in',
        'Rotate your wrist as you press',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=GWLYNJvHp5g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Floor_Press/0.jpg',
    ),
    'Reverse_Band_Bench_Press': ExerciseCoaching(
      howTo: [
        'Set a bench in a power rack and loop bands from the top of the rack down to each end of the bar so they help lift at the bottom.',
        'Unrack and lower the bar to your chest under control.',
        'Press it back up, driving hard through the triceps as the band tension drops off near the top.',
      ],
      formChecks: [
        'Anchor bands to the rack top',
        'Lower the bar to mid-chest',
        'Drive through triceps to lock out',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4YLD7HGEsR4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Bench_Press/0.jpg',
    ),
    'Reverse_Triceps_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and take a close, underhand grip about shoulder width.',
        'Unrack the bar and hold it locked over your chest.',
        'Lower it under control to your lower chest, keeping elbows tucked, then press back up to full lockout, driving through the triceps.',
      ],
      formChecks: [
        'Take an underhand close grip',
        'Keep your elbows tucked in',
        'Lower to your lower chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HGaYGsdTp4g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Triceps_Bench_Press/0.jpg',
    ),
    'Smith_Machine_Incline_Bench_Press': ExerciseCoaching(
      howTo: [
        'Set an incline bench under the Smith machine, with the bar set where your arms are almost fully extended.',
        'Lie back and grip slightly wider than shoulder width, then unrack.',
        'Lower the bar to your upper chest, then press up and slightly back to lockout.',
      ],
      formChecks: [
        'Set the bar over upper chest',
        'Grip just outside shoulders',
        'Drive up and slightly back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8urE8Z8AMQ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Incline_Bench_Press/0.jpg',
    ),
    'Standing_Cable_Chest_Press': ExerciseCoaching(
      howTo: [
        'Set both pulleys to chest height and grab a handle in each hand.',
        'Step forward into a staggered stance with elbows bent to ninety degrees.',
        'Press both handles forward until your arms extend and hands nearly meet, then return slowly to a full stretch.',
      ],
      formChecks: [
        'Stagger your stance',
        'Start with elbows at ninety',
        'Press until your hands meet',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sh92B-_2O48',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Cable_Chest_Press/0.jpg',
    ),
    'Svend_Press': ExerciseCoaching(
      howTo: [
        'Stand tall and press two light plates flat together at chest height, fingers pointing forward.',
        'Squeeze the plates hard to load the chest.',
        'Press them straight out until your arms lock, keep crushing them together, then draw them back to your chest.',
      ],
      formChecks: [
        'Crush the plates together',
        'Press straight out to lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cIoUZOnypS8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Svend_Press/0.jpg',
    ),
    'Wide-Grip_Barbell_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench with feet planted.',
        'Take a wide, overhand grip a few inches outside shoulder width and unrack the bar over your chest.',
        'Lower it to mid-chest with elbows flared out, then press back up to full lockout.',
      ],
      formChecks: [
        'Grip a hand-width outside shoulders',
        'Pin your shoulder blades back',
        'Flare your elbows out',
        'Lower to mid-chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ApAEFcT8tiY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Barbell_Bench_Press/0.jpg',
    ),
    'Wide-Grip_Decline_Barbell_Bench_Press': ExerciseCoaching(
      howTo: [
        'Lie on a decline bench with your feet locked in at the front.',
        'Take a wide, overhand grip outside shoulder width and unrack the bar over your lower chest.',
        'Lower it to your lower chest, then press back up to full lockout.',
      ],
      formChecks: [
        'Lock your feet in first',
        'Take a wide overhand grip',
        'Lower to your lower chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UH3w618WAAc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Decline_Barbell_Bench_Press/0.jpg',
    ),
    'Bent-Arm_Barbell_Pullover': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench holding a barbell over your chest with a shoulder-width grip and a bend in your elbows.',
        'Keeping that same elbow bend, lower the bar back over your head until you feel a stretch in the lats, then pull it back over your chest.',
      ],
      formChecks: [
        'Keep a fixed elbow bend',
        'Lower back until lats stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cZyygOeQek0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent-Arm_Barbell_Pullover/0.jpg',
    ),
    'Bent-Arm_Dumbbell_Pullover': ExerciseCoaching(
      howTo: [
        'Lie across a bench holding one dumbbell over the chest.',
        'Lower it behind the head with the elbows bent, feeling a stretch, then pull it back over the chest.',
      ],
      formChecks: [
        'Hips stay down, ribs braced',
        'Control the stretch behind the head',
        'Pull back over with the lats and chest',
        'Don\'t flare the lower back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0OeET0DOeHc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent-Arm_Dumbbell_Pullover/0.jpg',
    ),
    'Cable_Incline_Pushdown': ExerciseCoaching(
      howTo: [
        'Lie on an incline bench facing away from a high pulley, holding a straight bar overhead with a shoulder-width overhand grip.',
        'Keeping your arms straight, drive the bar down in an arc toward your thighs using the lats, then return slowly overhead.',
      ],
      formChecks: [
        'Keep your arms straight',
        'Sweep the bar to your thighs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BRkbf7tBE88',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Incline_Pushdown/0.jpg',
    ),
    'Front_Raise_And_Pullover': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench holding a barbell over your thighs, palms down and hands about 15 inches apart with a slight elbow bend.',
        'Raise the bar over your chest, then carry it back over your head into a pullover stretch.',
        'Reverse the path back to your thighs.',
      ],
      formChecks: [
        'Keep a slight elbow bend',
        'Raise the bar over your chest',
        'Carry it back into a pullover',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OO8x69XwRZY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Raise_And_Pullover/0.jpg',
    ),
    'Incline_Bench_Pull': ExerciseCoaching(
      howTo: [
        'Set an incline bench near 30 degrees and lie chest-down on it holding a barbell with an overhand grip.',
        'Let your arms hang straight toward the floor.',
        'Row the bar up to the bench by driving your elbows back and squeezing your shoulder blades, then lower under control.',
      ],
      formChecks: [
        'Keep your chest on the pad',
        'Let arms hang straight down',
        'Row your elbows back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9NejGnEDY5g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Bench_Pull/0.jpg',
    ),
    'Straight-Arm_Dumbbell_Pullover': ExerciseCoaching(
      howTo: [
        'Lie across or along a bench holding one dumbbell over the chest with a slight elbow bend.',
        'Lower it back behind the head until you feel a stretch, then pull it back over the chest.',
      ],
      formChecks: [
        'Keep a fixed, slight elbow bend',
        'Feel the stretch across the lats and chest',
        'Don\'t overarch the lower back',
        'Move slowly and under control',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fI8IZ2V88mo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight-Arm_Dumbbell_Pullover/0.jpg',
    ),
    'Wide-Grip_Decline_Barbell_Pullover': ExerciseCoaching(
      howTo: [
        'Lie on a decline bench with your legs locked in.',
        'Hold a barbell over your chest with a wide, overhand grip wider than shoulder width.',
        'Keeping a slight elbow bend, lower the bar back over your head until you feel a chest stretch, then pull it back over your chest.',
      ],
      formChecks: [
        'Lock your legs in',
        'Use a wide overhand grip',
        'Lower back until chest stretches',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_Tz-N-2U90Q',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Decline_Barbell_Pullover/0.jpg',
    ),
    'Alternate_Hammer_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell in each hand at arm\'s length, palms facing your torso and elbows close to your sides.',
        'Keeping your upper arms still, curl one dumbbell up with the neutral grip and squeeze, then lower it.',
        'Alternate arms each rep.',
      ],
      formChecks: [
        'Curl with a neutral grip',
        'Alternate arms each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=l7Wciibf_bo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Hammer_Curl/0.jpg',
    ),
    'Alternate_Incline_Dumbbell_Curl': ExerciseCoaching(
      howTo: [
        'Sit back on an incline bench with a dumbbell in each hand hanging at arm\'s length, palms forward and elbows close to your torso.',
        'Keeping the upper arms still, curl one dumbbell up and squeeze the biceps, then lower it.',
        'Alternate arms.',
      ],
      formChecks: [
        'Let your arms hang back',
        'Alternate arms each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=B4HGtMhGI2s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Incline_Dumbbell_Curl/0.jpg',
    ),
    'Barbell_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall holding the bar with an underhand shoulder-width grip and elbows pinned to the sides.',
        'Curl to the shoulders by contracting the biceps, then lower under control.',
      ],
      formChecks: [
        'Elbows stay pinned at the sides',
        'No swinging or hip drive',
        'Squeeze at the top',
        'Lower slowly to a full stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UfNLe7XbBQQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Curl/0.jpg',
    ),
    'Barbell_Curls_Lying_Against_An_Incline': ExerciseCoaching(
      howTo: [
        'Lie chest-down against an incline bench holding a barbell with your arms hanging straight down.',
        'Keeping the upper arms stationary, curl the bar up as high as you can and squeeze the biceps, then lower it slowly to full extension.',
      ],
      formChecks: [
        'Let the bar hang straight down',
        'Curl the bar up as high as you can',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=F6i5hRfLf2U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Curls_Lying_Against_An_Incline/0.jpg',
    ),
    'Cable_Hammer_Curls_-_Rope_Attachment': ExerciseCoaching(
      howTo: [
        'Attach a rope to a low pulley and stand facing it with a neutral grip on both ends.',
        'Keep your torso upright and elbows tucked to your sides.',
        'Curl the rope up toward your shoulders and squeeze the biceps, then lower under control.',
      ],
      formChecks: [
        'Grip both rope ends neutral',
        'Curl the rope to your shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cidWElB_XnQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Hammer_Curls_-_Rope_Attachment/0.jpg',
    ),
    'Cable_Preacher_Curl': ExerciseCoaching(
      howTo: [
        'With the upper arms flat on the preacher pad, curl the bar or dumbbell up, then lower under control to a near-full extension.',
      ],
      formChecks: [
        'Keep the upper arms flat on the pad',
        'Don\'t fully slam into lockout at the bottom',
        'Squeeze at the top',
        'Control every rep, no bouncing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oK1n5wKkWTU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Preacher_Curl/0.jpg',
    ),
    'Close-Grip_EZ_Bar_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall and grip the EZ bar at the inner handles with palms facing forward and elbows pinned to your sides.',
        'Curl the bar up toward your shoulders by contracting the biceps, then lower it under control to full extension.',
      ],
      formChecks: [
        'Grip the inner handles',
        'Pin elbows to your sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1bGHpNt0vhU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_EZ_Bar_Curl/0.jpg',
    ),
    'Close-Grip_Standing_Barbell_Curl': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder-width, holding a straight barbell palms-up with your hands a few inches apart.',
        'Keep your elbows tight to your torso and curl the bar up to your chest, then lower it back down slowly to a full stretch.',
      ],
      formChecks: [
        'Hands a few inches apart',
        'No swinging or leaning back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MLZxDHouma4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Standing_Barbell_Curl/0.jpg',
    ),
    'Concentration_Curls': ExerciseCoaching(
      howTo: [
        'Seated, brace the working elbow against the inner thigh with the dumbbell hanging.',
        'Curl to the shoulder, squeeze the biceps, then lower slowly.',
      ],
      formChecks: [
        'Upper arm stays fixed against the thigh',
        'Curl through a full range',
        'Squeeze hard at the top',
        'Lower slowly, no swing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=llD6MImgqe8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Concentration_Curls/0.jpg',
    ),
    'Cross_Body_Hammer_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell in each hand and palms facing in.',
        'Without rotating your wrist, curl one dumbbell up and across your body toward the opposite shoulder.',
        'Lower it back to your side and repeat with the other arm.',
      ],
      formChecks: [
        'Curl across to the opposite shoulder',
        'Neutral grip, no wrist twist',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fktCNgQiOjQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cross_Body_Hammer_Curl/0.jpg',
    ),
    'Drag_Curl': ExerciseCoaching(
      howTo: [
        'Hold a barbell with a palms-up grip and elbows drawn back behind your torso.',
        'Curl the bar up while dragging it straight along your body, driving your elbows back so the bar stays close.',
        'Lower it down along the same path.',
      ],
      formChecks: [
        'Drag the bar up your torso',
        'Drive your elbows back',
        'Stop at your lower chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cUJaw8aEa5g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Drag_Curl/0.jpg',
    ),
    'Dumbbell_Alternate_Bicep_Curl': ExerciseCoaching(
      howTo: [
        'Stand upright with a dumbbell in each hand, arms at your sides and palms facing your thighs.',
        'Curl one dumbbell up while rotating your palm to face up, keeping the upper arm still.',
        'Lower it and repeat with the other arm.',
      ],
      formChecks: [
        'Rotate palm up as you lift',
        'Keep upper arms fixed',
        'Alternate arms each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Nzgxzfo6YPY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Alternate_Bicep_Curl/0.jpg',
    ),
    'Dumbbell_Prone_Incline_Curl': ExerciseCoaching(
      howTo: [
        'Lie face down on an incline bench with your chest supported and shoulders near the top.',
        'Let your arms hang straight down holding a dumbbell in each hand.',
        'Curl the weights up toward your shoulders, then lower them under control to a full stretch.',
      ],
      formChecks: [
        'Lie chest-down on the bench',
        'Let arms hang straight down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JJqCt-pyq04',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Prone_Incline_Curl/0.jpg',
    ),
    'EZ-Bar_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall holding an EZ bar at the wide outer handles with palms facing forward and elbows close to your torso.',
        'Curl the bar up toward your shoulders by flexing the biceps, then lower it slowly back to a full stretch.',
      ],
      formChecks: [
        'Grip the wide outer handles',
        'Keep elbows close to your torso',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mANRmIqemHY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/EZ-Bar_Curl/0.jpg',
    ),
    'Flexor_Incline_Dumbbell_Curls': ExerciseCoaching(
      howTo: [
        'Sit back on an incline bench with a dumbbell in each hand, gripping toward the far end so the near side is heavier.',
        'Let your arms hang, then curl the weights up while keeping your wrists cocked back to take the stress off them.',
        'Lower slowly.',
      ],
      formChecks: [
        'Grip off-center, load the near end',
        'Keep the wrists cocked back',
        'Palms up throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cjnaJSYbG3g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flexor_Incline_Dumbbell_Curls/0.jpg',
    ),
    'Hammer_Curls': ExerciseCoaching(
      howTo: [
        'Stand holding the dumbbells with a neutral (palms-in) grip.',
        'Curl to the shoulders keeping the palms facing each other, then lower under control.',
      ],
      formChecks: [
        'Neutral grip throughout',
        'Keep the elbows fixed at the sides',
        'No swinging',
        'Control the lowering',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=wzQFTrlcDlg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hammer_Curls/0.jpg',
    ),
    'High_Cable_Curls': ExerciseCoaching(
      howTo: [
        'Stand between two high pulleys and grab a handle in each hand with your upper arms raised parallel to the floor and palms facing you.',
        'Curl both handles toward your head by flexing the biceps, then return to the start under control.',
      ],
      formChecks: [
        'Upper arms parallel to the floor',
        'Curl toward your ears',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WNoVCYCof9E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/High_Cable_Curls/0.jpg',
    ),
    'Incline_Hammer_Curls': ExerciseCoaching(
      howTo: [
        'Sit back against an incline bench with a dumbbell in each hand hanging straight down and palms facing in.',
        'Keeping a neutral grip, curl the weights up toward your shoulders without rotating your wrists.',
        'Lower them slowly to a full stretch.',
      ],
      formChecks: [
        'Neutral grip, no wrist turn',
        'Keep your back on the pad',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vN_U9kaRMJM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Hammer_Curls/0.jpg',
    ),
    'Incline_Inner_Biceps_Curl': ExerciseCoaching(
      howTo: [
        'Lie back on an incline bench with a dumbbell in each hand at arm\'s length and palms facing outward.',
        'Curl the weights up and outward toward your shoulders while keeping your palms turned out.',
        'Lower them under control to a full stretch.',
      ],
      formChecks: [
        'Turn your palms outward',
        'Curl up and out',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=tQoy6cilQb8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Inner_Biceps_Curl/0.jpg',
    ),
    'Lying_Cable_Curl': ExerciseCoaching(
      howTo: [
        'Attach a bar to a low pulley and lie on your back on the floor facing the stack.',
        'Grab the bar underhand at shoulder width with your arms extended toward the pulley.',
        'Curl the bar up toward your face, then lower it to full extension.',
      ],
      formChecks: [
        'Pin your elbows to the floor',
        'Underhand shoulder-width grip',
        'Curl the bar to your face',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fx0ZL3Kgacc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Cable_Curl/0.jpg',
    ),
    'Lying_Close-Grip_Bar_Curl_On_High_Pulley': ExerciseCoaching(
      howTo: [
        'Set a flat bench in front of a high pulley and grab the straight bar underhand at shoulder width.',
        'Lie back with your head over the bench end and arms extended up toward the pulley.',
        'Curl the bar down toward your forehead, then extend back up.',
      ],
      formChecks: [
        'Keep upper arms pointing up',
        'Curl the bar to your forehead',
        'Hinge only at the elbows',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Ro0e8PufCEc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Close-Grip_Bar_Curl_On_High_Pulley/0.jpg',
    ),
    'Lying_High_Bench_Barbell_Curl': ExerciseCoaching(
      howTo: [
        'Lie face down on a tall flat bench holding a barbell with a palms-up, shoulder-width grip.',
        'Let your arms hang straight down off the bench.',
        'Curl the bar up toward your shoulders by flexing the biceps, then lower it slowly to full extension.',
      ],
      formChecks: [
        'Lie chest-down, arms hanging',
        'Strict reps, no momentum',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HVgvZ4Xf70w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_High_Bench_Barbell_Curl/0.jpg',
    ),
    'Lying_Supine_Dumbbell_Curl': ExerciseCoaching(
      howTo: [
        'Lie face up on a flat bench with a dumbbell in each hand and your arms hanging down toward the floor at your sides.',
        'Keeping your upper arms close to your body, curl the dumbbells up toward your shoulders.',
        'Lower them back down to a full stretch.',
      ],
      formChecks: [
        'Let arms hang for a deep stretch',
        'Keep upper arms close to your torso',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=n3MXFaGzg5U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Supine_Dumbbell_Curl/0.jpg',
    ),
    'Machine_Preacher_Curls': ExerciseCoaching(
      howTo: [
        'Sit at the machine and rest the back of your upper arms flat on the pad.',
        'Grab the handles with an underhand grip.',
        'Curl the handles up until your biceps fully contract, then lower slowly until your arms are almost straight.',
      ],
      formChecks: [
        'Keep upper arms flat on the pad',
        'Ease out of the bottom, no bounce',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Ja6ZlIDONac',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Preacher_Curls/0.jpg',
    ),
    'One_Arm_Dumbbell_Preacher_Curl': ExerciseCoaching(
      howTo: [
        'Rest the back of one upper arm on a preacher bench and hold a dumbbell with an underhand grip.',
        'Curl the weight up until your biceps fully contracts, then lower it slowly until the arm is straight.',
        'Switch arms after the set.',
      ],
      formChecks: [
        'Back of the arm stays on the pad',
        'Straighten fully for a bottom stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fuK3nFvwgXk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Dumbbell_Preacher_Curl/0.jpg',
    ),
    'Overhead_Cable_Curl': ExerciseCoaching(
      howTo: [
        'Set both pulleys high and grab a handle in each hand.',
        'Stand tall between them with arms extended out at shoulder height, palms up.',
        'Curl both hands toward your ears until your biceps peak, then straighten your arms back out.',
      ],
      formChecks: [
        'Keep elbows high at shoulder level',
        'Curl your knuckles toward your ears',
        'Move only the forearms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=S7IBBKqWqog',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Overhead_Cable_Curl/0.jpg',
    ),
    'Preacher_Hammer_Dumbbell_Curl': ExerciseCoaching(
      howTo: [
        'Rest both upper arms on a preacher bench and hold a dumbbell in each hand with palms facing each other.',
        'Lower the dumbbells until your arms are fully extended, then curl them up until your biceps contract.',
        'Keep the neutral grip throughout.',
      ],
      formChecks: [
        'Keep palms facing each other, no twist',
        'Upper arms flat on the pad',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_37keawAZlg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Preacher_Hammer_Dumbbell_Curl/0.jpg',
    ),
    'Reverse_Barbell_Preacher_Curls': ExerciseCoaching(
      howTo: [
        'Grip an EZ-bar at shoulder width with your palms facing down.',
        'Rest the back of both upper arms on the preacher pad with arms extended.',
        'Curl the bar up until your biceps fully contract, then lower it slowly until your arms straighten.',
      ],
      formChecks: [
        'Grip the bar palms down',
        'Drive your knuckles up',
        'Keep upper arms on the pad',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DzvvfnoNseI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Barbell_Preacher_Curls/0.jpg',
    ),
    'Reverse_Cable_Curl': ExerciseCoaching(
      howTo: [
        'Attach a straight bar to a low pulley and grip it at shoulder width with palms facing down.',
        'Stand tall with elbows tucked to your sides.',
        'Curl the bar up toward your shoulders until your biceps contract, then lower it slowly until your arms are straight.',
      ],
      formChecks: [
        'Keep palms facing down',
        'Pin elbows to your sides',
        'Curl up without leaning back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HwB-DevuJjU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Cable_Curl/0.jpg',
    ),
    'Reverse_Plate_Curls': ExerciseCoaching(
      howTo: [
        'Stand tall holding a weight plate in both hands with your arms hanging straight and palms facing down.',
        'Curl the plate up toward your shoulders until your biceps contract, then lower it slowly until your arms are fully extended.',
      ],
      formChecks: [
        'Pinch the plate palms down',
        'Curl with elbows at your sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eNjUBRTgfYU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Plate_Curls/0.jpg',
    ),
    'Seated_Close-Grip_Concentration_Barbell_Curl': ExerciseCoaching(
      howTo: [
        'Sit on a flat bench with your legs spread and hold a barbell with a close, underhand grip between your knees.',
        'Rest the back of your upper arms against your inner thighs.',
        'Curl the bar up toward your chest, then lower it slowly until your arms extend.',
      ],
      formChecks: [
        'Set a close underhand grip',
        'Brace upper arms on your inner thighs',
        'Curl the bar to your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=K5nwaYAv5lI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Close-Grip_Concentration_Barbell_Curl/0.jpg',
    ),
    'Seated_Dumbbell_Curl': ExerciseCoaching(
      howTo: [
        'Sit on a flat bench holding a dumbbell in each hand at arm\'s length with elbows close to your sides.',
        'Curl the weights up while rotating your palms to face up, until your biceps contract.',
        'Lower slowly and rotate back to the start.',
      ],
      formChecks: [
        'Keep elbows pinned to your sides',
        'Rotate palms up as you curl',
        'Untwist to neutral on the way down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BsULGO70tcU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Curl/0.jpg',
    ),
    'Seated_Dumbbell_Inner_Biceps_Curl': ExerciseCoaching(
      howTo: [
        'Sit on the end of a flat bench holding a dumbbell in each hand at arm\'s length, elbows close and palms facing inward.',
        'Curl the weights up while rotating your palms to face up, squeezing your biceps at the top.',
        'Lower slowly back to neutral.',
      ],
      formChecks: [
        'Start with palms facing inward',
        'Twist palms up as you curl',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ScI03ZyzyDs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Inner_Biceps_Curl/0.jpg',
    ),
    'Spider_Curl': ExerciseCoaching(
      howTo: [
        'Lean your chest against the steep side of a preacher bench and let your arms hang straight down holding an EZ-bar underhand.',
        'Curl the bar up toward your shoulders until your biceps fully contract, then lower it slowly until your arms are straight.',
      ],
      formChecks: [
        'Chest flat on the steep pad',
        'Let your arms hang straight down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9Dd8iiEUs_Q',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Spider_Curl/0.jpg',
    ),
    'Standing_Biceps_Cable_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall holding a cable curl bar on a low pulley with a shoulder-width, palms-up grip.',
        'Keep your elbows tucked to your sides.',
        'Curl the bar up toward your shoulders until your biceps contract, then lower it slowly until your arms straighten.',
      ],
      formChecks: [
        'Keep elbows fixed at your sides',
        'Curl without swinging your body',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UsaY33N4KEw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Biceps_Cable_Curl/0.jpg',
    ),
    'Standing_Concentration_Curl': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell in your working hand and lean forward at the hips.',
        'Let that arm hang straight down toward the floor.',
        'Curl the weight up by flexing your elbow while keeping your upper arm still, then lower it slowly until your arm is straight.',
      ],
      formChecks: [
        'Hinge forward, let the arm hang',
        'Bend only at the elbow',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rAxZd2NvJig',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Concentration_Curl/0.jpg',
    ),
    'Standing_Dumbbell_Reverse_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell in each hand and your palms facing down, arms fully extended.',
        'Keep your elbows close to your sides and curl the weights up until your biceps contract.',
        'Lower them slowly until your arms are straight, holding the palms-down grip.',
      ],
      formChecks: [
        'Keep palms facing down',
        'Elbows stay close to your sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BfY-4WuwR8s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Reverse_Curl/0.jpg',
    ),
    'Standing_Inner-Biceps_Curl': ExerciseCoaching(
      howTo: [
        'Stand with a dumbbell in each hand at arm\'s length, elbows close to your sides and palms facing inward.',
        'Curl the weights up while rotating your palms to face up, squeezing your biceps at the top.',
        'Lower slowly and rotate back to a neutral grip.',
      ],
      formChecks: [
        'Rotate from neutral to palms up',
        'No torso swing to lift',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=F95ps05kwWk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Inner-Biceps_Curl/0.jpg',
    ),
    'Standing_One-Arm_Cable_Curl': ExerciseCoaching(
      howTo: [
        'Grab a single handle at the low pulley and step back so the cable stays taut.',
        'Pin your upper arm to your side and keep it still.',
        'Curl the handle up toward your shoulder by squeezing the biceps, then lower slowly to a full stretch.',
      ],
      formChecks: [
        'Pin your upper arm to your side',
        'Keep the cable taut at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=68hHB-pZxug',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_One-Arm_Cable_Curl/0.jpg',
    ),
    'Standing_One-Arm_Dumbbell_Curl_Over_Incline_Bench': ExerciseCoaching(
      howTo: [
        'Stand behind an incline bench and drape your working arm over the top of the pad, palm up, dumbbell hanging.',
        'Brace your free hand on the bench.',
        'Curl the dumbbell toward your shoulder, squeeze the biceps, then lower until the arm is straight.',
      ],
      formChecks: [
        'Back of your arm stays on the pad',
        'Straighten the arm fully at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DCoH-j3ip6g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_One-Arm_Dumbbell_Curl_Over_Incline_Bench/0.jpg',
    ),
    'Two-Arm_Dumbbell_Preacher_Curl': ExerciseCoaching(
      howTo: [
        'Sit at a preacher bench and set both upper arms flat on the pad, a dumbbell in each hand.',
        'Lower the dumbbells slowly until your arms are fully extended and the biceps stretch.',
        'Curl them back up until your forearms are just short of vertical.',
      ],
      formChecks: [
        'Upper arms flat on the pad',
        'Stop just short of vertical up top',
        'Ease into the bottom stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EL0eMqbACWg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Dumbbell_Preacher_Curl/0.jpg',
    ),
    'Wide-Grip_Standing_Barbell_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall holding a barbell with a wide grip, palms forward and elbows tucked to your sides.',
        'Keep your upper arms still and curl the bar up toward your chest by flexing the elbows.',
        'Squeeze at the top, then lower under control to full extension.',
      ],
      formChecks: [
        'Grip wider than shoulder width',
        'Keep elbows pinned to your sides',
        'No swinging or leaning back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vzPU8GgiTsg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Standing_Barbell_Curl/0.jpg',
    ),
    'Zottman_Curl': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell in each hand, palms facing in and elbows tucked.',
        'Curl up while rotating your palms to face upward.',
        'At the top turn your palms to face down, then lower slowly in that grip and rotate back to neutral at the bottom.',
      ],
      formChecks: [
        'Palms up as you curl',
        'Rotate to palms-down at the top',
        'Lower slow in the palms-down grip',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FSGDM9-dZ9w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Zottman_Curl/0.jpg',
    ),
    'Zottman_Preacher_Curl': ExerciseCoaching(
      howTo: [
        'Rest your upper arms on the preacher pad holding a dumbbell in each hand at the top with palms facing down.',
        'Lower slowly keeping the palms down until the arms straighten, then rotate to palms up at the bottom.',
        'Curl back to the top and rotate to palms down again.',
      ],
      formChecks: [
        'Upper arms flat on the pad',
        'Lower with palms down',
        'Rotate to palms up at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pCQo4VJxmhI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Zottman_Preacher_Curl/0.jpg',
    ),
    'Balance_Board': ExerciseCoaching(
      howTo: [
        'Set a balance board on the floor and step onto it with both feet.',
        'Find your center and steady the board so neither edge touches down.',
        'Make small ankle and calf adjustments to hold the balance, keeping your core tight and eyes forward.',
      ],
      formChecks: [
        'Keep both edges off the floor',
        'Correct through your ankles',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Iv-ulz-_qe4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Balance_Board/0.jpg',
    ),
    'Calf_Press': ExerciseCoaching(
      howTo: [
        'Set the balls of your feet on the platform with heels hanging off and legs only slightly bent.',
        'Press through the balls of your feet to push the platform away, fully extending your ankles.',
        'Lower your heels back down until you feel a deep calf stretch.',
      ],
      formChecks: [
        'Push to full ankle extension',
        'Let the heels sink at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dhRz1Ns60Zg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Press/0.jpg',
    ),
    'Calf_Raise_On_A_Dumbbell': ExerciseCoaching(
      howTo: [
        'Hold a sturdy object for balance and place the balls of both feet on a dumbbell handle, heels on the floor.',
        'Rise onto your toes as high as you can by squeezing the calves.',
        'Lower your heels back toward the floor under control for a full stretch.',
      ],
      formChecks: [
        'Rise as high as you can',
        'Steady the wobbling handle',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SRUtMJ0tE2A',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Raise_On_A_Dumbbell/0.jpg',
    ),
    'Calf_Raises_-_With_Bands': ExerciseCoaching(
      howTo: [
        'Stand on the middle of an exercise band with the balls of both feet, splitting the length evenly.',
        'Bring the handles up to your shoulders to load the band.',
        'Rise onto your toes against the resistance, then lower your heels slowly.',
      ],
      formChecks: [
        'Center the band under both feet',
        'Keep even tension on both sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=a2xjbhP4MkY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Raises_-_With_Bands/0.jpg',
    ),
    'Donkey_Calf_Raises': ExerciseCoaching(
      howTo: [
        'Set the balls of your feet on the platform and bend forward at the hips, resting the pad across your lower back and hips.',
        'Support your upper body on your forearms.',
        'Push up onto your toes by contracting the calves, then lower your heels for a full stretch.',
      ],
      formChecks: [
        'Hinge forward at the hips',
        'Pad on your hips, not your spine',
        'Push all the way onto your toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=iGwAYr8Iqmg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Donkey_Calf_Raises/0.jpg',
    ),
    'Dumbbell_Seated_One-Leg_Calf_Raise': ExerciseCoaching(
      howTo: [
        'Sit on a bench and rest a dumbbell on your thigh just above the knee.',
        'Place the ball of that foot on a block with the heel hanging off.',
        'Raise your heel by pressing through the ball of the foot and squeezing the calf, then lower slowly to a stretch.',
      ],
      formChecks: [
        'Rest the weight above your knee',
        'Full squeeze up, full stretch down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VZSgIfD4LsY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Seated_One-Leg_Calf_Raise/0.jpg',
    ),
    'Rocking_Standing_Calf_Raise': ExerciseCoaching(
      howTo: [
        'Set a loaded barbell across your upper back inside a squat rack and step out.',
        'Rise up onto the balls of your feet as high as you can, squeezing the calves.',
        'Rock back onto your heels and lift your toes, then rock forward onto your toes again.',
      ],
      formChecks: [
        'Rise onto your toes, then rock back',
        'Lift your toes at the heel end',
        'Rock smoothly, no bouncing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Gu4I8EaTy1I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rocking_Standing_Calf_Raise/0.jpg',
    ),
    'Seated_Calf_Raise': ExerciseCoaching(
      howTo: [
        'Sit with the pad on the lower thighs and the balls of the feet on the block.',
        'Lower the heels to a stretch, then press up as high as possible onto the toes.',
      ],
      formChecks: [
        'Full stretch at the bottom',
        'Press up as high as possible',
        'Pause at the top',
        'Keep the reps smooth and controlled',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3ZRe_QpvRPg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Calf_Raise/0.jpg',
    ),
    'Smith_Machine_Reverse_Calf_Raises': ExerciseCoaching(
      howTo: [
        'Rest the Smith bar across your upper back and stand on a platform with your heels on it and the balls of your feet off the front edge.',
        'Drop your toes down toward the floor, then lift them as high as you can by flexing the front of your lower legs.',
      ],
      formChecks: [
        'Keep your heels on the platform',
        'Lift your toes toward your shins',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nOtr_C8i0J8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Reverse_Calf_Raises/0.jpg',
    ),
    'Standing_Barbell_Calf_Raise': ExerciseCoaching(
      howTo: [
        'Set a loaded barbell across your upper back and place the balls of your feet on a block or plate with heels hanging off.',
        'Rise up onto your toes as high as possible, squeezing the calves hard.',
        'Lower your heels below the block for a deep stretch.',
      ],
      formChecks: [
        'Rise to full tip-toe',
        'Sink the heels below the block',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4vK3pLd4Akg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Barbell_Calf_Raise/0.jpg',
    ),
    'Standing_Calf_Raises': ExerciseCoaching(
      howTo: [
        'Set the shoulder pads to your height and stand with the balls of your feet on the platform edge, toes forward.',
        'Lower your heels as far as they go for a deep stretch in the calves.',
        'Press up onto your toes as high as possible and squeeze hard at the top.',
      ],
      formChecks: [
        'Drop the heels for a deep stretch',
        'Drive up high onto the big toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Km0QS46bTEA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Calf_Raises/0.jpg',
    ),
    'Bodyweight_Flyes': ExerciseCoaching(
      howTo: [
        'Set two loaded EZ bars parallel on the floor and take a push-up position with a hand on each bar.',
        'Roll the bars apart to lower your chest toward the floor while keeping your arms slightly bent.',
        'Pull the bars back together and squeeze your chest to return.',
      ],
      formChecks: [
        'Hold a straight plank line',
        'Keep a slight bend in the elbows',
        'Roll the bars out to a chest stretch',
        'Pull the bars back under the chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sLANZx9TAnQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Flyes/0.jpg',
    ),
    'Butterfly': ExerciseCoaching(
      howTo: [
        'Sit with your back flat against the pad and grip the handles with your upper arms parallel to the floor.',
        'Squeeze the handles together in front of your chest until they nearly touch.',
        'Return slowly under control until you feel a stretch across the chest.',
      ],
      formChecks: [
        'Back flat, upper arms parallel',
        'Squeeze the handles until they nearly touch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eGjt4lk6g34',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Butterfly/0.jpg',
    ),
    'Cable_Crossover': ExerciseCoaching(
      howTo: [
        'Set the pulleys high, take a handle in each hand and stagger your stance with a slight forward lean.',
        'With a soft elbow bend, bring the handles together in front in a hugging arc, then return under control.',
      ],
      formChecks: [
        'Keep a fixed, slight bend in the elbows',
        'Move at the shoulder, not the elbow',
        'Squeeze the chest as the hands meet',
        'Control the stretch, don\'t let it snap back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hhruLxo9yZU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Crossover/0.jpg',
    ),
    'Cable_Iron_Cross': ExerciseCoaching(
      howTo: [
        'Set both pulleys high and take a handle in each hand, standing between them with your arms out to the sides.',
        'Keep your chest up and pull the handles down and together in front of your hips in a wide arc.',
        'Squeeze the chest, then return along the same path.',
      ],
      formChecks: [
        'Keep the chest up, ribs down',
        'Sweep down together to your hips',
        'Hold a slight bend in the elbows',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AImXgelsfPc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Iron_Cross/0.jpg',
    ),
    'Dumbbell_Flyes': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench holding a dumbbell in each hand over your chest, palms facing and elbows slightly bent.',
        'Open your arms and lower the dumbbells out to the sides until you feel a stretch across the chest.',
        'Bring them back up over your chest in the same arc.',
      ],
      formChecks: [
        'Keep a soft bend in the elbows',
        'Lower out wide to a chest stretch',
        'Arc them back up, don\'t press',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UKwkChzThig',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Flyes/0.jpg',
    ),
    'Flat_Bench_Cable_Flyes': ExerciseCoaching(
      howTo: [
        'Set a flat bench between two low pulleys and lie back with a handle in each hand, arms out to your sides.',
        'Keep a slight bend in your elbows and bring the handles up and together over your chest in an arc.',
        'Squeeze, then lower back out to the stretch.',
      ],
      formChecks: [
        'Bring the handles together over the chest',
        'Keep the elbows slightly bent throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Zv3yalOU8Ag',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Cable_Flyes/0.jpg',
    ),
    'Incline_Cable_Flye': ExerciseCoaching(
      howTo: [
        'Set both pulleys at floor level and place a 45-degree incline bench between them.',
        'Lie back with a handle in each hand and your arms open wide.',
        'Bring the handles up and together over your upper chest, then lower them back out until you feel a stretch.',
      ],
      formChecks: [
        'Drive the handles over the upper chest',
        'Meet the hands up high',
        'Open wide for an upper-chest stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LGDCjwO-hFg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Cable_Flye/0.jpg',
    ),
    'Low_Cable_Crossover': ExerciseCoaching(
      howTo: [
        'Set both pulleys low and grab a handle in each hand with palms facing forward.',
        'Step forward into a staggered stance to load the cables, arms down at your sides.',
        'Sweep your hands up and together in front of your chest, then lower them back down along the same arc.',
      ],
      formChecks: [
        'Stagger your stance for a base',
        'Scoop the hands up and inward',
        'Squeeze the inner chest to finish',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=wnFEC_34Bls',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Low_Cable_Crossover/0.jpg',
    ),
    'One-Arm_Flat_Bench_Dumbbell_Flye': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench holding one dumbbell over your chest with a neutral grip and a slight elbow bend.',
        'Lower the dumbbell out to the side in an arc until you feel a stretch across the chest.',
        'Bring it back up over your chest and squeeze.',
      ],
      formChecks: [
        'Keep hips and shoulders square',
        'Lower in an arc to a full stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9dLnatNHd-8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Flat_Bench_Dumbbell_Flye/0.jpg',
    ),
    'Single-Arm_Cable_Crossover': ExerciseCoaching(
      howTo: [
        'Set the pulley high and take the handle in one hand, stepping forward so the arm is extended out and back.',
        'Keep your chest up and pull the handle down and across your body toward the opposite hip.',
        'Squeeze the chest, then return slowly to the stretch.',
      ],
      formChecks: [
        'Pull down across to the far hip',
        'Stand tall, don\'t twist the torso',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7_IJU_4YIwU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Arm_Cable_Crossover/0.jpg',
    ),
    'Cable_Wrist_Curl': ExerciseCoaching(
      howTo: [
        'Kneel or sit at a flat bench in front of a low pulley with a straight bar, gripping it palms-up.',
        'Rest your forearms on the bench with your wrists just past the edge.',
        'Let the bar roll down to your fingers, then curl your wrists up as high as you can.',
      ],
      formChecks: [
        'Let the bar roll down to the fingers',
        'Curl it back up with the wrists',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WVAaKJvToe0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Wrist_Curl/0.jpg',
    ),
    'Dumbbell_Lying_Pronation': ExerciseCoaching(
      howTo: [
        'Lie face down on a flat bench with one arm hanging off the side, elbow bent to 90 degrees and a dumbbell in that hand.',
        'Start with your palm facing up.',
        'Rotate your forearm to turn the palm down, then control it back to the start.',
      ],
      formChecks: [
        'Turn the palm from up to down',
        'Keep the elbow fixed at 90',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=M_pkj9o2cnM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_Pronation/0.jpg',
    ),
    'Dumbbell_Lying_Supination': ExerciseCoaching(
      howTo: [
        'Lie on your side on a flat bench with your top arm bent to 90 degrees, holding a dumbbell with the palm facing down.',
        'Rotate your forearm to turn the palm all the way up.',
        'Lower it back under control to the start.',
      ],
      formChecks: [
        'Turn the palm from down to up',
        'Keep the elbow tucked and still',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=2TeMNKXAXOQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_Supination/0.jpg',
    ),
    'Finger_Curls': ExerciseCoaching(
      howTo: [
        'Hold a barbell with a shoulder-width, palms-up grip and let your arms hang at your sides.',
        'Open your fingers and let the bar roll down to your fingertips.',
        'Curl your fingers back up to roll the bar into your palms and grip it firmly.',
      ],
      formChecks: [
        'Let the bar roll to the fingertips',
        'Curl it back up with the fingers',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mp61xNRZcrk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Finger_Curls/0.jpg',
    ),
    'Palms-Down_Wrist_Curl_Over_A_Bench': ExerciseCoaching(
      howTo: [
        'Kneel at a flat bench and rest your forearms flat on it, gripping a barbell palms-down with your wrists just past the edge.',
        'Lower the bar by bending your wrists down toward the floor.',
        'Curl your wrists back up to lift the bar as high as you can.',
      ],
      formChecks: [
        'Rest the forearms flat on the bench',
        'Curl the knuckles up as high as you can',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jtQslxR3f0A',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Palms-Down_Wrist_Curl_Over_A_Bench/0.jpg',
    ),
    'Plate_Pinch': ExerciseCoaching(
      howTo: [
        'Put two wide-rimmed plates together with the smooth sides facing out, then pinch them between your fingers and thumb.',
        'Lift to arm\'s length by your side and hold steady, keeping the plates level.',
        'Keep squeezing until your grip nearly gives, then set them down.',
      ],
      formChecks: [
        'Pinch with thumb and fingertips',
        'Hold level until your grip fails',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jFTV3DQf3HE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plate_Pinch/0.jpg',
    ),
    'Seated_Dumbbell_Palms-Up_Wrist_Curl': ExerciseCoaching(
      howTo: [
        'Sit on a flat bench holding a dumbbell in each hand with your palms facing up.',
        'Rest your forearms along your thighs so the wrists hang just past your knees.',
        'Let the dumbbells roll down toward your fingers, then curl them up by flexing your wrists fully.',
      ],
      formChecks: [
        'Roll the bells down to your fingers',
        'Curl up, only the wrists move',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3rsKOL8scsU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Palms-Up_Wrist_Curl/0.jpg',
    ),
    'Seated_One-Arm_Dumbbell_Palms-Up_Wrist_Curl': ExerciseCoaching(
      howTo: [
        'Sit on a flat bench with a dumbbell in your right hand, palm up.',
        'Lean forward and lay your forearm along your right thigh so the wrist hangs over the knee.',
        'Let the weight roll down to your fingers, then curl the wrist up as high as it goes before switching sides.',
      ],
      formChecks: [
        'Pin your forearm to the thigh',
        'Roll to fingertips then curl up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=o0UQmNnu1LQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_One-Arm_Dumbbell_Palms-Up_Wrist_Curl/0.jpg',
    ),
    'Seated_Palm-Up_Barbell_Wrist_Curl': ExerciseCoaching(
      howTo: [
        'Sit on a flat bench and hold a barbell with an underhand, shoulder-width grip.',
        'Lean forward and rest both forearms on your thighs with the wrists just past your knees.',
        'Let the bar roll down your fingers, then curl it up by flexing your wrists through a full arc.',
      ],
      formChecks: [
        'Keep both forearms on your thighs',
        'Roll bar to fingers then flex up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9sZlJZ41Lm8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Palm-Up_Barbell_Wrist_Curl/0.jpg',
    ),
    'Seated_Two-Arm_Palms-Up_Low-Pulley_Wrist_Curl': ExerciseCoaching(
      howTo: [
        'Set a bench in front of a low pulley fitted with a straight bar.',
        'Sit and rest your forearms on your thighs, holding the bar palms-up with the cable pulling toward the machine.',
        'Let your wrists roll open against the tension, then curl the bar up by flexing them.',
      ],
      formChecks: [
        'Keep the cable under tension',
        'Flex only the wrists up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_QhXMgl0xOI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Two-Arm_Palms-Up_Low-Pulley_Wrist_Curl/0.jpg',
    ),
    'Standing_Olympic_Plate_Hand_Squeeze': ExerciseCoaching(
      howTo: [
        'Stand tall holding a weight plate by its ridge in each hand, arms at your sides with palms facing in.',
        'Let each plate slide down toward your fingertips by easing your grip, then squeeze your fingers to crush it back up into your palm.',
      ],
      formChecks: [
        'Let it slide to your fingertips',
        'Crush it back into your palm',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=wzE0g81F4Y0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Olympic_Plate_Hand_Squeeze/0.jpg',
    ),
    'Standing_Palms-Up_Barbell_Behind_The_Back_Wrist_Curl': ExerciseCoaching(
      howTo: [
        'Stand upright and hold a barbell behind your glutes at arm\'s length, hands shoulder-width apart.',
        'Let the bar roll down toward your fingers by opening your wrists, then curl it back up by flexing your wrists.',
        'Keep your arms straight behind you the whole time.',
      ],
      formChecks: [
        'Keep arms straight behind you',
        'Roll to fingers then flex the wrists',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Aemd_LwZliQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Palms-Up_Barbell_Behind_The_Back_Wrist_Curl/0.jpg',
    ),
    'Wrist_Roller': ExerciseCoaching(
      howTo: [
        'Stand tall gripping a loaded wrist roller with both hands, palms down.',
        'Raise your arms straight in front until they are parallel to the floor.',
        'Wind the weight up by rolling the bar hand over hand, then slowly reverse the roll to lower it back down.',
      ],
      formChecks: [
        'Hold arms out parallel to floor',
        'Wind hand over hand',
        'Unwind slowly to lower',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=C4urEGe0zsQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wrist_Roller/0.jpg',
    ),
    'Wrist_Rotations_with_Straight_Bar': ExerciseCoaching(
      howTo: [
        'Hold a barbell with both hands, palms facing down and hands shoulder-width apart, out in front of your thighs.',
        'Alternating between hands, extend each wrist upward as if winding the bar toward you, then let it rotate back.',
        'Keep a steady, controlled rhythm.',
      ],
      formChecks: [
        'Wind up one wrist at a time',
        'Keep arms still, no swing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ytyBPIiaLMc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wrist_Rotations_with_Straight_Bar/0.jpg',
    ),
    'Band_Hip_Adductions': ExerciseCoaching(
      howTo: [
        'Anchor a band to a low post and loop it around the ankle of the leg nearest the post.',
        'Stand side-on and step out until the band pulls that leg outward.',
        'Keep the leg straight and sweep it across your body past the standing leg, then return slowly against the band.',
      ],
      formChecks: [
        'Sweep the leg across your body',
        'Keep the working leg straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ugWMLte1FiM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Hip_Adductions/0.jpg',
    ),
    'Butt_Lift_Bridge': ExerciseCoaching(
      howTo: [
        'Lie on your back with your knees bent and feet flat about shoulder-width apart, arms resting at your sides.',
        'Push through your heels to drive your hips up until your body forms a straight line from knees to shoulders, then lower back down.',
      ],
      formChecks: [
        'Drive through your heels',
        'Lift to a straight knee-to-shoulder line',
        'Squeeze glutes, don\'t arch the back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aVKXkwh49mk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Butt_Lift_Bridge/0.jpg',
    ),
    'Downward_Facing_Balance': ExerciseCoaching(
      howTo: [
        'Lie facedown over an exercise ball and walk your hands forward along the floor until the ball sits under your hips.',
        'Straighten your arms to hold yourself up, then lift both legs by extending your knees and hips until they line up with your torso.',
        'Hold, then lower.',
      ],
      formChecks: [
        'Keep the ball still under your hips',
        'Lift legs level with your torso',
        'Squeeze glutes to raise them',
        'Keep your back flat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=PRja65swvic',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Downward_Facing_Balance/0.jpg',
    ),
    'Glute_Kickback': ExerciseCoaching(
      howTo: [
        'Get on your hands and knees with your arms under your shoulders and your back flat.',
        'Keeping the knee bent at ninety degrees, raise one leg back and up until the thigh lines up with your torso.',
        'Squeeze the glute, lower with control, then switch legs.',
      ],
      formChecks: [
        'Lift the thigh level with your torso',
        'Keep the knee bent ninety',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BNDw4ciQoQI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Glute_Kickback/0.jpg',
    ),
    'Leg_Lift': ExerciseCoaching(
      howTo: [
        'Stand tall beside a squat rack or chair and hold on for balance, feet close together.',
        'Keeping one leg straight, lift it back behind you as far as your glute allows without leaning forward.',
        'Squeeze at the top, lower under control, then switch legs.',
      ],
      formChecks: [
        'Lift the straight leg behind you',
        'Stay upright, don\'t lean forward',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jgh6sGwtTwk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Lift/0.jpg',
    ),
    'Monster_Walk': ExerciseCoaching(
      howTo: [
        'Loop one band around your ankles and another around your knees, then set your feet shoulder-width so both bands pull taut.',
        'Take short, controlled steps forward, alternating feet and never letting them drift closer than shoulder width.',
        'Keep tension on the bands throughout.',
      ],
      formChecks: [
        'Keep feet wider than shoulders',
        'Drive knees out, don\'t let them cave',
        'Take short even steps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kfm8QOPfD9k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Monster_Walk/0.jpg',
    ),
    'One-Legged_Cable_Kickback': ExerciseCoaching(
      howTo: [
        'Strap a low cable cuff to your ankle and face the stack, holding the frame for support.',
        'Keep a slight bend in the knee and hips.',
        'Kick the working leg straight back and up by squeezing the glute, then bring it forward under control.',
      ],
      formChecks: [
        'Drive the heel back and up',
        'Move from the hip, not the spine',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dGaUbIQ62Eg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Legged_Cable_Kickback/0.jpg',
    ),
    'Thigh_Abductor': ExerciseCoaching(
      howTo: [
        'Sit on the abductor machine with the pads against your outer thighs and grip the handles.',
        'Keep your upper body still and back against the seat.',
        'Push your knees outward as far as comfortable by driving the pads apart, then bring them back slowly.',
      ],
      formChecks: [
        'Push the knees apart',
        'Keep the torso still, no rocking',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=G_8LItOiZ0Q',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Thigh_Abductor/0.jpg',
    ),
    'Thigh_Adductor': ExerciseCoaching(
      howTo: [
        'Sit on the inner thighs machine with the pads against your inner thighs and your legs spread apart.',
        'Grip the handles and keep your upper body still.',
        'Squeeze your legs together against the pads, then let them open back slowly under control.',
      ],
      formChecks: [
        'Pull the knees together',
        'Don\'t let it stretch you too far',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CjAVezAggkI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Thigh_Adductor/0.jpg',
    ),
    'Tricep_Dumbbell_Kickback': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell in each hand and hinge forward at the waist until your torso is near parallel to the floor, back flat.',
        'Tuck your upper arms to your sides.',
        'Extend the weights back by straightening your elbows and squeezing the triceps, then lower under control.',
      ],
      formChecks: [
        'Pin upper arms to your sides',
        'Straighten fully at the elbow',
        'Move only the forearm',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SD6VFvTQcCI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tricep_Dumbbell_Kickback/0.jpg',
    ),
    'Ball_Leg_Curl': ExerciseCoaching(
      howTo: [
        'Lie on your back with your heels on top of an exercise ball and legs extended.',
        'Raise your hips so your body forms a straight line from shoulders to feet.',
        'Dig your heels in and curl the ball toward your glutes by bending your knees, then roll it back out.',
      ],
      formChecks: [
        'Keep hips up, don\'t let them sag',
        'Steady the ball, no wobbling',
        'Curl heels toward your glutes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dvL7uz8UVNc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ball_Leg_Curl/0.jpg',
    ),
    'Floor_Glute-Ham_Raise': ExerciseCoaching(
      howTo: [
        'Kneel upright with your feet anchored under something stable and your body straight from knees to head.',
        'Lower your torso toward the floor slowly by letting your knees extend, keeping hips locked.',
        'Pull yourself back up using your hamstrings, catching with your hands if needed.',
      ],
      formChecks: [
        'Stay straight from knees to head',
        'Fight the fall, lower slowly',
        'Push through hands if you stall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AjcGo5xJvNI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Floor_Glute-Ham_Raise/0.jpg',
    ),
    'Lying_Leg_Curls': ExerciseCoaching(
      howTo: [
        'Lie face down with the pad on the lower calves.',
        'Curl the heels toward the glutes, squeeze the hamstrings, then lower under control.',
      ],
      formChecks: [
        'Keep the hips down on the pad',
        'Curl through a full range',
        'Squeeze the hamstrings at the top',
        'Don\'t let the weight drop back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lUH80pneL5w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Leg_Curls/0.jpg',
    ),
    'Platform_Hamstring_Slides': ExerciseCoaching(
      howTo: [
        'Lie on your back with legs extended and a towel or slider under one heel on a smooth floor.',
        'Flex that knee to slide the heel toward your glutes while the other leg stays straight, then slide it back out under control.',
        'Switch legs after your reps.',
      ],
      formChecks: [
        'One leg slides, the other stays straight',
        'Slide smoothly, control the return',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=D8rOfbVvjZg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Platform_Hamstring_Slides/0.jpg',
    ),
    'Prone_Manual_Hamstring': ExerciseCoaching(
      howTo: [
        'Lie face down with your legs straight and a partner\'s hand pressed against your heel.',
        'Curl your leg up by flexing the knee, driving against the resistance they provide.',
        'Lower back down slowly as your partner keeps pushing against the movement.',
      ],
      formChecks: [
        'Drive the heel up against resistance',
        'Keep hips pinned to the floor',
        'Fight hard on the way down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=79WtCLoDRrI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Prone_Manual_Hamstring/0.jpg',
    ),
    'Seated_Band_Hamstring_Curl': ExerciseCoaching(
      howTo: [
        'Anchor a band low and sit on a bench placed a couple of feet away.',
        'Loop the band behind your ankles with your legs straight out.',
        'Flex your knees to pull your ankles back underneath the bench against the band, then straighten your legs slowly.',
      ],
      formChecks: [
        'Pull ankles back under the bench',
        'Return slow, don\'t let the band win',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=M6vrWU9owLc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Band_Hamstring_Curl/0.jpg',
    ),
    'Seated_Leg_Curl': ExerciseCoaching(
      howTo: [
        'Sit with the pad on the lower calves and thighs secured.',
        'Curl the heels down and back under the seat, squeeze, then return under control.',
      ],
      formChecks: [
        'Keep the thighs pinned under the pad',
        'Full range curl',
        'Squeeze the hamstrings',
        'Control the return',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Orxowest56U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Leg_Curl/0.jpg',
    ),
    'Standing_Leg_Curl': ExerciseCoaching(
      howTo: [
        'Stand at the leg curl machine and hook one ankle behind the padded lever, keeping a slight bend in the working knee.',
        'Brace your torso against the support.',
        'Curl your heel up toward your glute by flexing the hamstring, then lower the pad back down slowly.',
      ],
      formChecks: [
        'Curl the heel to your glute',
        'Keep the hips still, no swinging',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CusyCbRlttM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Leg_Curl/0.jpg',
    ),
    'Isometric_Neck_Exercise_-_Front_And_Back': ExerciseCoaching(
      howTo: [
        'Sit or stand with your head in a neutral position and place both hands on your forehead.',
        'Push your head forward into your hands while your hands resist so the head stays still, and hold.',
        'Switch your hands to the back of your head and press backward against them the same way.',
      ],
      formChecks: [
        'Push in, but let nothing move',
        'Build force gradually, no jerking',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gvJ8akM18x8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Neck_Exercise_-_Front_And_Back/0.jpg',
    ),
    'Isometric_Neck_Exercise_-_Sides': ExerciseCoaching(
      howTo: [
        'Hold your head in a neutral position and place your left hand against the left side of your head.',
        'Press your head into your hand while the hand resists so nothing actually moves, and hold.',
        'Repeat on the right side with your right hand.',
      ],
      formChecks: [
        'Press into the hand, no tilting',
        'Work both sides equally',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dSwNfqs8NjY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Neck_Exercise_-_Sides/0.jpg',
    ),
    'Lying_Face_Up_Plate_Neck_Resistance': ExerciseCoaching(
      howTo: [
        'Lie face up on a flat bench with your shoulders just past the end so your head hangs free.',
        'Hold a weight plate flat on your forehead with both hands.',
        'Lower your head back by dropping it toward the floor, then curl your chin toward your chest to raise the plate.',
      ],
      formChecks: [
        'Keep both hands on the plate',
        'Curl the chin, move only the neck',
        'Use a slow, short range',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=__mHZwz1pzM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Face_Up_Plate_Neck_Resistance/0.jpg',
    ),
    'Seated_Head_Harness_Neck_Resistance': ExerciseCoaching(
      howTo: [
        'Fit a loaded head harness and sit at the end of a flat bench with your feet wider than shoulder width.',
        'Lean forward slightly and let your chin drop toward your chest to lower the weight.',
        'Raise it by extending your neck until your head is upright again.',
      ],
      formChecks: [
        'Start light and move slowly',
        'Extend the neck, keep the body still',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lqCumM-_MXE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Head_Harness_Neck_Resistance/0.jpg',
    ),
    'Cable_Hip_Adduction': ExerciseCoaching(
      howTo: [
        'Attach an ankle cuff to a low pulley and fix it to the leg nearest the stack.',
        'Stand side-on and step away so the cable pulls that leg outward under tension.',
        'Pull the working leg across your body past the standing leg, then let it travel back out slowly.',
      ],
      formChecks: [
        'Sweep the leg across your body',
        'Stay steady on the standing leg',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=P1pLE1jmnI0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Hip_Adduction/0.jpg',
    ),
    'Leg_Extensions': ExerciseCoaching(
      howTo: [
        'Sit with the pad on the lower shins and knees at the seat\'s pivot.',
        'Extend the legs to straight, squeeze the quads, then lower under control.',
      ],
      formChecks: [
        'Line the knee up with the machine\'s pivot',
        'Squeeze at full extension',
        'Don\'t slam into lockout',
        'Control the negative',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4ZDm5EbiFI8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Extensions/0.jpg',
    ),
    'Single-Leg_Leg_Extension': ExerciseCoaching(
      howTo: [
        'Sit in the machine with the pad against your lower shin just above the ankle and your knee lined up with the pivot.',
        'Extend one leg until the knee locks out, squeezing the quad hard at the top.',
        'Lower it back down slowly under control.',
      ],
      formChecks: [
        'Line your knee up with the pivot',
        'Lock out, no kicking or swinging',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=82IuSLk5zNc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Leg_Extension/0.jpg',
    ),
    'Alternating_Deltoid_Raise': ExerciseCoaching(
      howTo: [
        'Stand holding a dumbbell in each hand with elbows slightly bent.',
        'Raise the weights to the front to shoulder height and lower, then on the next rep raise them out to the sides.',
        'Keep alternating front and side without swinging.',
      ],
      formChecks: [
        'Alternate front then side',
        'Soft elbows, no swinging',
        'Stop at shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=PD32vFPbyR4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Deltoid_Raise/0.jpg',
    ),
    'Back_Flyes_-_With_Bands': ExerciseCoaching(
      howTo: [
        'Anchor a band around a squat rack post at chest height and hold a handle in each hand.',
        'Step back until the band is taut with your arms extended in front of you.',
        'Pull the handles apart in a wide arc out to your sides, then return with control.',
      ],
      formChecks: [
        'Step back until the band is taut',
        'Sweep arms wide to your sides',
        'Keep arms straight and parallel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HO_E7LhmrMs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Back_Flyes_-_With_Bands/0.jpg',
    ),
    'Band_Pull_Apart': ExerciseCoaching(
      howTo: [
        'Hold a band with both hands, arms extended straight out in front at shoulder height.',
        'Keeping your elbows locked, pull the band apart by driving your hands out to your sides until it meets your chest.',
        'Return slowly to the front.',
      ],
      formChecks: [
        'Keep elbows locked, pull to your chest',
        'Stay tall, don\'t shrug up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=smSSXITNpCI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Pull_Apart/0.jpg',
    ),
    'Battling_Ropes': ExerciseCoaching(
      howTo: [
        'Anchor a heavy rope at its center and hold one end in each hand with arms at your sides.',
        'Drop into a slight athletic quarter-squat and brace your core.',
        'Rapidly raise and lower each arm to drive alternating waves down the rope, keeping them fast and continuous.',
      ],
      formChecks: [
        'Sit into a quarter-squat',
        'Drive fast, tall waves',
        'Keep both arms moving evenly',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QqvfQQFVX5E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Battling_Ropes/0.jpg',
    ),
    'Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench': ExerciseCoaching(
      howTo: [
        'Set an incline bench and stand holding a dumbbell in each hand.',
        'Hinge forward until your forehead rests on the top of the bench, back flat and arms hanging straight down.',
        'Raise the dumbbells out to your sides to shoulder level, then lower slowly.',
      ],
      formChecks: [
        'Keep your forehead on the bench',
        'Raise elbows to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Iz2JBbffw48',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench/0.jpg',
    ),
    'Bent_Over_Low-Pulley_Side_Lateral': ExerciseCoaching(
      howTo: [
        'Grab a low pulley handle with one hand and hinge at the waist until your torso is near parallel to the floor.',
        'Brace your free hand on your thigh and let the working arm hang across your body.',
        'Raise the handle out to the side to shoulder height, then lower under control.',
      ],
      formChecks: [
        'Hinge till your torso is parallel',
        'Brace free hand on your thigh',
        'Raise the handle out wide',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SKxd6hggfuw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bent_Over_Low-Pulley_Side_Lateral/0.jpg',
    ),
    'Cable_Internal_Rotation': ExerciseCoaching(
      howTo: [
        'Sit or stand side-on to a low pulley and grab the handle with the arm closest to the machine.',
        'Pin that elbow to your side, bent at 90 degrees, forearm pointing out toward the cable.',
        'Rotate your forearm inward across your belly, then return slowly to the stretch.',
      ],
      formChecks: [
        'Pin your elbow to your side',
        'Rotate the forearm across your belly',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=C_-CN1iji3c',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Internal_Rotation/0.jpg',
    ),
    'Cable_Rear_Delt_Fly': ExerciseCoaching(
      howTo: [
        'Set both pulleys above head height and grab the left handle with your right hand and the right handle with your left so the cables cross in front.',
        'Pull your arms apart and back in a wide arc until they reach out to your sides.',
        'Squeeze the rear delts, then return under control.',
      ],
      formChecks: [
        'Cross the cables in front',
        'Sweep wide and back to your sides',
        'Keep arms level with your shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=er15V96hG5U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Rear_Delt_Fly/0.jpg',
    ),
    'Cable_Seated_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Place a flat bench between two opposing low pulleys and sit on it.',
        'Grab each handle with the opposite hand so the cables cross under your knees.',
        'Raise both handles out to your sides to shoulder height, then lower slowly against the tension.',
      ],
      formChecks: [
        'Cross the cables under your knees',
        'Raise out to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xDrYB81QXmY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Seated_Lateral_Raise/0.jpg',
    ),
    'Car_Drivers': ExerciseCoaching(
      howTo: [
        'Stand tall holding a weight plate at the 3 and 9 o\'clock positions, palms facing each other.',
        'Extend your arms straight out in front at shoulder height.',
        'Rotate the plate side to side like a steering wheel while keeping your arms locked out and level.',
      ],
      formChecks: [
        'Hold arms straight out in front',
        'Turn the plate like a steering wheel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=orkwUebzZAE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Car_Drivers/0.jpg',
    ),
    'Circus_Bell': ExerciseCoaching(
      howTo: [
        'Stand over the circus bell with it between your feet and grip the thick handle with both hands.',
        'Clean it to your shoulder by driving through your hips and knees.',
        'Press the bell overhead until your arm locks out, then lower it back to the shoulder under control.',
      ],
      formChecks: [
        'Drive through hips to clean it',
        'Stay braced, don\'t arch back',
        'Press to full overhead lockout',
        'Lower back to your shoulder',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hfZU7KAIQuQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Circus_Bell/0.jpg',
    ),
    'Crucifix': ExerciseCoaching(
      howTo: [
        'Hold a weight in each hand and raise both arms straight out to your sides until they are level with your shoulders.',
        'Keep your arms locked and parallel to the floor.',
        'Hold this position statically for time, fighting to stop the weights drifting down.',
      ],
      formChecks: [
        'Hold arms parallel to the floor',
        'Fight to stop the weights dropping',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=P2zvIej-Ous',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Crucifix/0.jpg',
    ),
    'Dumbbell_Lying_One-Arm_Rear_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Set a bench to a low incline and lie chest-down on it holding a dumbbell in one hand.',
        'Let that arm hang straight down and hold the bench with the other hand for support.',
        'Raise the dumbbell out to your side to shoulder level, then lower slowly under control.',
      ],
      formChecks: [
        'Lie chest-down on the incline',
        'Lead the elbow to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=teENbRLL9iM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_One-Arm_Rear_Lateral_Raise/0.jpg',
    ),
    'Dumbbell_Lying_Rear_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Lie chest-down on a low-incline bench holding a dumbbell in each hand with palms facing each other.',
        'Let both arms hang straight below you.',
        'Raise the dumbbells out to your sides to shoulder level, leading with your elbows, then lower both slowly.',
      ],
      formChecks: [
        'Palms facing, arms hanging down',
        'Raise both elbows out wide',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FGuZ-Y5YQFU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lying_Rear_Lateral_Raise/0.jpg',
    ),
    'Dumbbell_Raise': ExerciseCoaching(
      howTo: [
        'Stand tall holding a dumbbell in each hand at your sides, palms facing your thighs, elbows slightly bent.',
        'Raise both arms out to the sides until they reach shoulder height.',
        'Lower them back down under control.',
      ],
      formChecks: [
        'Lead with the elbows',
        'Keep the traps down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XPPfnSEATJA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Raise/0.jpg',
    ),
    'Dumbbell_Scaption': ExerciseCoaching(
      howTo: [
        'Stand holding a light dumbbell in each hand at your sides with thumbs pointing up.',
        'Raise both arms up and out at a 30-degree angle from your body to shoulder height, forming a Y.',
        'Lower under control.',
      ],
      formChecks: [
        'Point thumbs up',
        'Raise along the Y',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XOAIGRH90RY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Scaption/0.jpg',
    ),
    'External_Rotation': ExerciseCoaching(
      howTo: [
        'Lie on your side on a bench holding a dumbbell in the top hand, elbow tucked to your ribs and bent 90 degrees so the weight rests near your belly.',
        'Rotate the forearm up toward the ceiling.',
        'Lower it back down slowly.',
      ],
      formChecks: [
        'Pin the elbow to your ribs',
        'Rotate only the forearm',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=v5bPOsQbq7g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/External_Rotation/0.jpg',
    ),
    'Front_Cable_Raise': ExerciseCoaching(
      howTo: [
        'Face away from a low pulley gripping the single handle with one hand, arm hanging straight in front of your thigh.',
        'Raise the cable forward and up to shoulder height with a slight elbow bend.',
        'Lower it back down under control.',
      ],
      formChecks: [
        'Raise to shoulder height',
        'Don\'t lean back',
        'Keep the cable taut',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vtH93qBItdk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Cable_Raise/0.jpg',
    ),
    'Front_Incline_Dumbbell_Raise': ExerciseCoaching(
      howTo: [
        'Sit against an incline bench set to 30 to 60 degrees, holding a dumbbell in each hand with arms straight down and palms facing back.',
        'Raise both arms forward to shoulder height.',
        'Lower them back down slowly.',
      ],
      formChecks: [
        'Keep your back on the pad',
        'Raise straight to the front',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AbdHWZuYo_A',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Incline_Dumbbell_Raise/0.jpg',
    ),
    'Front_Plate_Raise': ExerciseCoaching(
      howTo: [
        'Stand tall gripping a weight plate at the 3 and 9 o\'clock edges, palms facing each other, arms extended down with a slight elbow bend.',
        'Raise the plate forward to shoulder height.',
        'Lower it back down under control.',
      ],
      formChecks: [
        'Grip at 3 and 9',
        'Don\'t rock the torso',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HN8HYJTOl8c',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Plate_Raise/0.jpg',
    ),
    'Front_Two-Dumbbell_Raise': ExerciseCoaching(
      howTo: [
        'Stand with a straight torso holding a dumbbell in each hand in front of your thighs, palms facing you.',
        'Raise both arms forward together to shoulder height.',
        'Lower them back down under control.',
      ],
      formChecks: [
        'Raise both arms together',
        'No torso swing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OSrB7wqTgac',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Two-Dumbbell_Raise/0.jpg',
    ),
    'Kettlebell_Pirate_Ships': ExerciseCoaching(
      howTo: [
        'Take a wide stance and hold one kettlebell with both hands, arms hanging at waist level.',
        'Turn to one side and swing the bell up to head height, then bring it back to center.',
        'Swing to the opposite side.',
      ],
      formChecks: [
        'Pivot through the torso',
        'Keep the arms long',
        'Swing up to head height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Q9t1xZRFnow',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Pirate_Ships/0.jpg',
    ),
    'Kettlebell_Thruster': ExerciseCoaching(
      howTo: [
        'Hold two kettlebells racked at your shoulders, feet shoulder-width.',
        'Squat down until your thighs are parallel, then drive up through the legs and press both bells overhead as you stand.',
        'Lower back to the shoulders and descend again.',
      ],
      formChecks: [
        'Hit parallel in the squat',
        'Drive up through the legs',
        'Press as you stand',
        'Lock out overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=y0QfDZvoJcQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Thruster/0.jpg',
    ),
    'Landmine_Linear_Jammer': ExerciseCoaching(
      howTo: [
        'Anchor a landmine bar and hold the handles at your shoulders in an athletic, even stance.',
        'Dip by flexing the hips and knees, then drive through the legs and extend the arms to press the bar up and forward.',
        'Return to your shoulders and repeat.',
      ],
      formChecks: [
        'Drive with the legs, not just the arms',
        'Even athletic stance',
        'Follow the bar\'s arc',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NOrpEdNoOVQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Landmine_Linear_Jammer/0.jpg',
    ),
    'Lateral_Raise_-_With_Bands': ExerciseCoaching(
      howTo: [
        'Stand on an exercise band with a handle in each hand, palms facing your thighs, hands just inside shoulder width.',
        'Raise both arms out to the sides to shoulder height against the band tension.',
        'Lower them back down slowly.',
      ],
      formChecks: [
        'Lead with the elbows',
        'Fight the band down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=-TkAT5ezO1w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Raise_-_With_Bands/0.jpg',
    ),
    'Log_Lift': ExerciseCoaching(
      howTo: [
        'Stand over the log and grip the handles, hips back and chest up.',
        'Clean it to your chest by extending the hips and knees, roll it onto your shoulders, then press it overhead to lockout.',
        'Lower it back to the floor under control.',
      ],
      formChecks: [
        'Chest up on the pull',
        'Explode through the hips',
        'Roll it high to rack',
        'Lock the press out',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fP2c06_iKfc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Log_Lift/0.jpg',
    ),
    'Lying_One-Arm_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Lie chest-down on a flat bench holding a dumbbell in one hand, palm neutral, arm hanging toward the floor.',
        'Raise the arm out to the side up to shoulder height with a slight elbow bend.',
        'Lower it back down slowly.',
      ],
      formChecks: [
        'Keep your chest on the bench',
        'Raise out to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VqFAWmgnb8I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_One-Arm_Lateral_Raise/0.jpg',
    ),
    'Lying_Rear_Delt_Raise': ExerciseCoaching(
      howTo: [
        'Lie chest-down on a flat bench holding a dumbbell in each hand, palms facing your torso and elbows slightly bent.',
        'Raise both arms out to the sides until level with your shoulders, squeezing the rear delts.',
        'Lower under control.',
      ],
      formChecks: [
        'Raise to the shoulder line',
        'Don\'t pinch the shoulder blades',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lXuWPjI9dTw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Rear_Delt_Raise/0.jpg',
    ),
    'One-Arm_Incline_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Lie on your side on an incline bench with your lower shoulder against the pad, holding a dumbbell in your top hand across your body near your navel.',
        'Raise the top arm out and up to shoulder height.',
        'Lower it back down slowly.',
      ],
      formChecks: [
        'Keep the low shoulder pinned',
        'Raise up to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1bdqUV0Ri4k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Incline_Lateral_Raise/0.jpg',
    ),
    'One-Arm_Side_Laterals': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell in one hand and grip a steady upright like an incline bench with your other hand.',
        'Lean toward your lifting arm and away from the support so the weight hangs out from your body.',
        'Raise the dumbbell out to the side to shoulder height, then lower slowly.',
      ],
      formChecks: [
        'Lean away from the support',
        'Lead with the elbow',
        'Raise to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FGU9j1P5L-w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Side_Laterals/0.jpg',
    ),
    'Power_Partials': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell in each hand at arms length, palms facing your body and elbows close to your torso.',
        'Raise the dumbbells out to the sides through a short partial range.',
        'Pulse them up and down continuously without fully lowering.',
      ],
      formChecks: [
        'Pulse through a short range',
        'Never fully lower',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=v8J6PQ1iLBg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Partials/0.jpg',
    ),
    'Reverse_Flyes': ExerciseCoaching(
      howTo: [
        'Lie chest-down on an incline bench holding a dumbbell in each hand with a neutral grip, arms hanging with a slight elbow bend.',
        'Raise the weights out to the sides in an arc, squeezing the rear delts, then lower under control.',
      ],
      formChecks: [
        'Chest stays on the pad',
        'Slight fixed elbow bend',
        'Squeeze the rear delts',
        'No swinging',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Zo4Iwb1qgNI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Flyes/0.jpg',
    ),
    'Reverse_Flyes_With_External_Rotation': ExerciseCoaching(
      howTo: [
        'Lie chest-down on an incline bench set to 30 degrees with a dumbbell in each hand hanging below you.',
        'Raise your arms out to the sides in a wide arc while rotating your thumbs up and back.',
        'Squeeze the rear delts at the top, then lower and reverse the rotation.',
      ],
      formChecks: [
        'Rotate thumbs up and back',
        'Squeeze the rear delts',
        'Keep the arc wide',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xLKQB7r-bec',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Flyes_With_External_Rotation/0.jpg',
    ),
    'Seated_Bent-Over_Rear_Delt_Raise': ExerciseCoaching(
      howTo: [
        'Sit on the end of a flat bench with your feet together and a dumbbell beside each calf.',
        'Bend forward at the waist, keeping your back flat, and let the weights hang under your knees.',
        'Raise the dumbbells out to the sides to shoulder height, then lower them slowly.',
      ],
      formChecks: [
        'Keep chest pressed to thighs',
        'Lead with the elbows out',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=duDSzPBALSQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Bent-Over_Rear_Delt_Raise/0.jpg',
    ),
    'Seated_Side_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Seated with dumbbells at the sides and a slight elbow bend, raise the arms out to about shoulder height leading with the elbows, then lower under control.',
      ],
      formChecks: [
        'Lead with the elbows, not the hands',
        'Raise to about shoulder height, no higher',
        'Don\'t shrug or swing',
        'Lower slowly under control',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xDrYB81QXmY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Side_Lateral_Raise/0.jpg',
    ),
    'Side_Lateral_Raise': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell in each hand by your sides, palms facing in.',
        'Keeping your torso still and elbows slightly bent, raise the weights out to the sides until they reach shoulder height.',
        'Lower them back to your sides under control.',
      ],
      formChecks: [
        'Keep a slight bend in the elbows',
        'Stop at shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=z-kOn7flIZg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Lateral_Raise/0.jpg',
    ),
    'Side_Laterals_to_Front_Raise': ExerciseCoaching(
      howTo: [
        'Stand holding a dumbbell in each hand with your elbows slightly bent.',
        'Raise both weights straight out in front to shoulder height, then lower them.',
        'Next raise them out to your sides to shoulder height and lower again, alternating front and side each rep.',
      ],
      formChecks: [
        'Raise straight to the front',
        'Then raise out to the side',
        'Stop each at shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6vdhFbacXms',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Laterals_to_Front_Raise/0.jpg',
    ),
    'Single_Dumbbell_Raise': ExerciseCoaching(
      howTo: [
        'Take a wide stance and hold one dumbbell with both hands, cupping the top head of the bell.',
        'Let it hang at arms length in front of your waist.',
        'Raise the dumbbell straight up in front of you until it is above shoulder height, then lower it under control.',
      ],
      formChecks: [
        'Cup the top of the bell',
        'Keep both arms straight',
        'Raise above shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XPPfnSEATJA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Dumbbell_Raise/0.jpg',
    ),
    'Single-Arm_Linear_Jammer': ExerciseCoaching(
      howTo: [
        'Anchor a barbell in a landmine and bring the loaded end up to one shoulder, taking a wide stance.',
        'Hold it at the front of your shoulder with one hand.',
        'Drive the bar up and forward explosively until your arm is extended, then return it to your shoulder.',
      ],
      formChecks: [
        'Take a wide stance',
        'Drive up through your legs',
        'Press up and forward',
        'Finish with the arm extended',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XkvwvOje1DM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Arm_Linear_Jammer/0.jpg',
    ),
    'Sled_Reverse_Flye': ExerciseCoaching(
      howTo: [
        'Attach two handles to a sled and face it, backing up until the line has tension.',
        'Hold both handles at arms length near waist height with your knees slightly bent.',
        'Raise your arms out to the sides in a wide arc against the resistance, then let them return forward.',
      ],
      formChecks: [
        'Keep the arms wide',
        'Pull out against the sled',
        'Control the return forward',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BisIi4cagtI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Reverse_Flye/0.jpg',
    ),
    'Smith_Incline_Shoulder_Raise': ExerciseCoaching(
      howTo: [
        'Set an incline bench under a Smith machine and lie back with the bar at nearly full arm extension.',
        'Grip the bar overhand with your arms straight.',
        'Push the bar upward a few inches by extending through your shoulders, keeping your elbows locked, then lower slowly.',
      ],
      formChecks: [
        'Keep the elbows locked',
        'Push up just a few inches',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7E5TExnR4W0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Incline_Shoulder_Raise/0.jpg',
    ),
    'Standing_Dumbbell_Straight-Arm_Front_Delt_Raise_Above_Head': ExerciseCoaching(
      howTo: [
        'Stand holding a dumbbell in front of each thigh, palms facing in and arms straight.',
        'Raise the weights forward in a wide semicircular arc, keeping your arms locked, until they finish overhead at arms length.',
        'Lower them back down along the same path under control.',
      ],
      formChecks: [
        'Sweep out in a wide arc',
        'Keep the arms locked',
        'Finish overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=glkYhT0ZFmE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Straight-Arm_Front_Delt_Raise_Above_Head/0.jpg',
    ),
    'Standing_Front_Barbell_Raise_Over_Head': ExerciseCoaching(
      howTo: [
        'Stand tall holding a barbell against your thighs with an overhand grip slightly narrower than shoulder width.',
        'Keeping your arms straight, raise the bar forward and up in a smooth arc until it finishes overhead.',
        'Lower it back down to your thighs under control.',
      ],
      formChecks: [
        'Grip just inside shoulder width',
        'Keep the arms straight',
        'Finish the bar overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Ytffw4cHBh0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Front_Barbell_Raise_Over_Head/0.jpg',
    ),
    'Standing_Low-Pulley_Deltoid_Raise': ExerciseCoaching(
      howTo: [
        'Stand to one side of a low pulley and grip the single handle with an overhand grip, letting that arm rest across the front of your body.',
        'Steady yourself with the other hand on the machine.',
        'Raise the handle out to the side and up to shoulder height, then lower slowly.',
      ],
      formChecks: [
        'Start with the arm across your body',
        'Raise out to the side',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mitSn2x0bAs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Low-Pulley_Deltoid_Raise/0.jpg',
    ),
    'Straight_Raises_on_Incline_Bench': ExerciseCoaching(
      howTo: [
        'Lie face down on an incline bench and grip a barbell on the floor with an overhand grip, arms straight and hanging below you.',
        'Raise the bar forward and up in a straight arc to shoulder height, then lower it slowly.',
        'Keep your arms locked throughout.',
      ],
      formChecks: [
        'Keep your chest on the bench',
        'Raise to shoulder height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UhNzKr6TKEY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight_Raises_on_Incline_Bench/0.jpg',
    ),
    'Barbell_Shrug': ExerciseCoaching(
      howTo: [
        'Hold the bar in front of the thighs with straight arms.',
        'Shrug the shoulders straight up toward the ears, hold briefly, then lower under control.',
      ],
      formChecks: [
        'Lift straight up, don\'t roll the shoulders',
        'Keep the arms straight',
        'Squeeze the traps at the top',
        'Control the lowering',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=larn3Asl6oM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Shrug/0.jpg',
    ),
    'Cable_Shrugs': ExerciseCoaching(
      howTo: [
        'Grip a bar attached to a low pulley with an overhand, shoulder-width grip and stand tall close to the machine.',
        'Let your arms hang straight with the bar in front of you.',
        'Shrug your shoulders straight up toward your ears as high as possible, then lower them slowly.',
      ],
      formChecks: [
        'Shrug straight up to your ears',
        'Keep the arms hanging straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=D_GwLy10F3k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Shrugs/0.jpg',
    ),
    'Calf-Machine_Shoulder_Shrug': ExerciseCoaching(
      howTo: [
        'Step onto the calf machine and settle the shoulder pads on top of your shoulders.',
        'Stand tall with a straight torso and arms hanging at your sides.',
        'Drive your shoulders straight up toward your ears, squeeze the traps hard, then lower under control.',
      ],
      formChecks: [
        'Drive shoulders up to your ears',
        'Keep arms straight, don\'t roll',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6_sx_2YpJkw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf-Machine_Shoulder_Shrug/0.jpg',
    ),
    'Clean_Shrug': ExerciseCoaching(
      howTo: [
        'Hold a barbell at mid-thigh with a shoulder-width overhand or hook grip.',
        'Keep your back flat and your torso leaned slightly forward with arms straight.',
        'Shrug your shoulders explosively toward your ears, then control the bar back down.',
      ],
      formChecks: [
        'Start the bar at mid-thigh',
        'Shrug up fast and hard',
        'Arms stay straight, traps do the work',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FLIFCFMyx80',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_Shrug/0.jpg',
    ),
    'Leverage_Shrug': ExerciseCoaching(
      howTo: [
        'Load the machine and stand directly between the handles.',
        'Grip the top handles at your sides, keep your chest up and eyes forward.',
        'Shrug your shoulders straight up toward your ears, hold the squeeze, then lower under control.',
      ],
      formChecks: [
        'Shrug straight up to your ears',
        'Chest up, keep arms straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=M2xg36giXU0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Shrug/0.jpg',
    ),
    'Middle_Back_Shrug': ExerciseCoaching(
      howTo: [
        'Lie chest-down on an incline bench with a dumbbell in each hand, arms hanging straight down and palms facing each other.',
        'Keeping your arms straight, pull your shoulder blades back and together to lift the weights slightly, then lower under control.',
      ],
      formChecks: [
        'Squeeze shoulder blades together',
        'Keep arms straight, lift from the back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oDTT5LR1iTY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Middle_Back_Shrug/0.jpg',
    ),
    'Smith_Machine_Behind_the_Back_Shrug': ExerciseCoaching(
      howTo: [
        'Set the Smith bar at thigh height and stand in front of it so the bar rests behind your legs.',
        'Take a shoulder-width overhand grip, unhook, and stand tall with arms straight.',
        'Shrug your shoulders up toward your ears, then lower under control.',
      ],
      formChecks: [
        'Keep the bar close to your glutes',
        'Shrug straight up',
        'Stand tall, don\'t lean back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=u4aiG-KFWrc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Behind_the_Back_Shrug/0.jpg',
    ),
    'Snatch_Shrug': ExerciseCoaching(
      howTo: [
        'Hold a barbell at mid-thigh with a wide snatch-width overhand or hook grip.',
        'Keep your back flat and your torso leaned slightly forward with arms straight.',
        'Shrug your shoulders powerfully toward your ears, then control the bar back down.',
      ],
      formChecks: [
        'Take a wide snatch-width grip',
        'Shrug up explosively',
        'Keep arms straight, no arm pull',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=I19BuNBtYXA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Shrug/0.jpg',
    ),
    'Band_Skull_Crusher': ExerciseCoaching(
      howTo: [
        'Anchor a band low behind a bench and lie down with the band running past your head.',
        'Hold the band with your elbows bent and upper arms pointing straight up.',
        'Extend at the elbows until your arms are straight, then bend them back toward your forehead.',
      ],
      formChecks: [
        'Point your elbows at the ceiling',
        'Move only your forearms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cGTHzM1eJdo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Skull_Crusher/0.jpg',
    ),
    'Bench_Dips': ExerciseCoaching(
      howTo: [
        'Sit on the edge of a bench and grip the edge beside your hips, then walk your feet out and lift your hips off.',
        'Lower your body by bending your elbows until they reach about 90 degrees.',
        'Press through your palms to push back up to straight arms.',
      ],
      formChecks: [
        'Keep your back close to the bench',
        'Bend elbows to about 90 degrees',
        'Point elbows straight back',
        'Don\'t drop too low',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DW754-lPvPw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Dips/0.jpg',
    ),
    'Body_Tricep_Press': ExerciseCoaching(
      howTo: [
        'Set a bar in a rack at chest height and take a shoulder-width grip.',
        'Step back with feet together so you lean into the bar with arms straight.',
        'Bend only at the elbows to lower your head toward the bar, then extend your arms to press your body back.',
      ],
      formChecks: [
        'Keep your body in one straight line',
        'Hinge only at the elbows',
        'Keep your elbows high',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ufsLbTx9gYE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Body_Tricep_Press/0.jpg',
    ),
    'Body-Up': ExerciseCoaching(
      howTo: [
        'Start in a forearm plank on your toes with a straight torso and forearms shoulder-width apart.',
        'Press your palms into the floor and straighten your arms to push up onto your hands.',
        'Lower back down to your forearms under control.',
      ],
      formChecks: [
        'Keep hips level, no sagging',
        'Press palms to lock arms straight',
        'Lower back onto your forearms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fDK4uJFMXP8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Body-Up/0.jpg',
    ),
    'Cable_Lying_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench at the end of a low pulley and hold the straight bar with a narrow overhand grip.',
        'Start with your arms extended and the bar over your face.',
        'Bend your elbows to lower the bar toward your forehead, then extend to press it back up.',
      ],
      formChecks: [
        'Keep elbows tucked and still',
        'Lower the bar toward your forehead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MwfWEn04I8I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Lying_Triceps_Extension/0.jpg',
    ),
    'Cable_One_Arm_Tricep_Extension': ExerciseCoaching(
      howTo: [
        'Stand facing a high pulley and hold the single handle in one hand with an underhand grip.',
        'Pin your upper arm to your side with the elbow bent.',
        'Extend your elbow to push the handle down until your arm is straight, then let it rise under control.',
      ],
      formChecks: [
        'Pin your upper arm to your side',
        'Straighten fully at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DTkMHGVKv10',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_One_Arm_Tricep_Extension/0.jpg',
    ),
    'Cable_Rope_Overhead_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Facing away from the pulley with the rope overhead and elbows by the ears, extend the arms forward and up, then return to a stretch behind the head.',
      ],
      formChecks: [
        'Keep the upper arms by the ears',
        'Elbows point forward, not out',
        'Full extension at the top',
        'Control the stretch behind the head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1u18yJELsh0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cable_Rope_Overhead_Triceps_Extension/0.jpg',
    ),
    'Chain_Handle_Extension': ExerciseCoaching(
      howTo: [
        'Clip chains to two cable handles and lie back on a flat bench holding one in each hand.',
        'Point your elbows straight up with your forearms lowered and the chains hanging.',
        'Extend your elbows to press the handles up until your arms lock out, then lower.',
      ],
      formChecks: [
        'Point your elbows straight up',
        'Press the handles to full lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Ta12euVr2-o',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chain_Handle_Extension/0.jpg',
    ),
    'Close-Grip_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'Stand a dumbbell upright on a flat bench, then lie perpendicular across it so only your shoulders are supported with your hips dropped below.',
        'Grip the top of the dumbbell with both hands and press it straight up over your chest, then lower under control.',
      ],
      formChecks: [
        'Hold one dumbbell in both hands',
        'Keep elbows tucked to your sides',
        'Press straight up over your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cefsgoFQNNA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Dumbbell_Press/0.jpg',
    ),
    'Close-Grip_EZ-Bar_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and take a narrow grip on an EZ bar, holding it over your chest with arms straight and elbows tucked in.',
        'Lower the bar to your lower chest, keeping your elbows close to your body.',
        'Press it back up until your arms lock out.',
      ],
      formChecks: [
        'Grip the inner bends, narrow',
        'Keep elbows close to your body',
        'Lower the bar to your lower chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AWMrpxPMIm0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_EZ-Bar_Press/0.jpg',
    ),
    'Decline_Close-Grip_Bench_To_Skull_Crusher': ExerciseCoaching(
      howTo: [
        'Secure your legs at the end of a decline bench and lie back.',
        'Take a close grip, unrack the barbell, and hold it over your chest with arms locked.',
        'Lower the bar toward your forehead by bending only the elbows, then press it back up and tuck the elbows in like a close-grip bench.',
      ],
      formChecks: [
        'Lower the bar to your forehead',
        'Press up and tuck the bar back',
        'Keep the grip close, elbows in',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sLae_WpobiM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Close-Grip_Bench_To_Skull_Crusher/0.jpg',
    ),
    'Decline_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Secure your legs on a decline bench and lie back with a dumbbell in each hand, palms facing each other.',
        'Press them up over your shoulders with arms extended.',
        'Lower the dumbbells toward the sides of your head by bending the elbows, then extend back up.',
      ],
      formChecks: [
        'Palms face each other',
        'Lower to the sides of your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=W6k1sbXKJ6g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Decline_EZ_Bar_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Secure your legs at the end of a decline bench and lie back.',
        'Take a close grip on the EZ bar, unrack it, and hold it over your chest with arms locked.',
        'Lower the bar toward your forehead by bending the elbows, then extend back to the top.',
      ],
      formChecks: [
        'Lower the EZ bar to your forehead',
        'Keep upper arms vertical',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=53hk6U9K13I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_EZ_Bar_Triceps_Extension/0.jpg',
    ),
    'Dip_Machine': ExerciseCoaching(
      howTo: [
        'Sit securely in the dip machine and grasp the handles with elbows bent about 90 degrees.',
        'Keep your elbows tucked at your sides.',
        'Press the handles down by extending your elbows until your arms are straight, then return under control to the start.',
      ],
      formChecks: [
        'Tuck elbows at your sides',
        'Press down to straight arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pMarNxAvHPc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dip_Machine/0.jpg',
    ),
    'Dumbbell_One-Arm_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Sit or stand tall and raise a dumbbell overhead in one hand with the arm fully extended.',
        'Keep your upper arm close to your head and pointing up.',
        'Lower the dumbbell behind your head by bending the elbow, then extend your arm to press it back overhead.',
      ],
      formChecks: [
        'Keep the upper arm pointing up',
        'Lower behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kZ-ReOdn2qk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_One-Arm_Triceps_Extension/0.jpg',
    ),
    'Dumbbell_Tricep_Extension_-Pronated_Grip': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench with two dumbbells pressed above your shoulders, arms extended and palms facing forward.',
        'Keep your elbows tucked in.',
        'Lower the dumbbells toward your forehead by bending the elbows, then extend your arms back up to the top.',
      ],
      formChecks: [
        'Palms face forward throughout',
        'Lower toward your forehead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=2GtAcrzUAYo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Tricep_Extension_-Pronated_Grip/0.jpg',
    ),
    'EZ-Bar_Skullcrusher': ExerciseCoaching(
      howTo: [
        'Lie on a bench holding the EZ-bar over the forehead with elbows fixed.',
        'Lower the bar toward the forehead or just behind the head, then extend back up.',
      ],
      formChecks: [
        'Keep the elbows fixed, don\'t flare',
        'Only the forearms move',
        'Lower under control',
        'Stop short of locking the elbows hard',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9Ti0Z9bF_P0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/EZ-Bar_Skullcrusher/0.jpg',
    ),
    'Incline_Barbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Lie back on an incline bench set between 45 and 75 degrees, holding a barbell with an overhand grip just inside shoulder width.',
        'Extend your arms to bring the bar overhead with elbows in.',
        'Lower the bar toward the top of your head by bending the elbows, then extend back up.',
      ],
      formChecks: [
        'Set the bench 45 to 75 degrees',
        'Lower the bar to the top of your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Uc5a-SxWPWQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Barbell_Triceps_Extension/0.jpg',
    ),
    'JM_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and hold a barbell at arm\'s length with a close grip and elbows tucked.',
        'Lower the bar toward your upper neck by bending the elbows while letting them drift slightly forward, keeping the bar close.',
        'Stop near the throat, then press back up to lockout.',
      ],
      formChecks: [
        'Lower the bar toward your throat',
        'Let your elbows drift forward',
        'Keep the bar close to your neck',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Tih5iHyELsE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/JM_Press/0.jpg',
    ),
    'Kneeling_Cable_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Set a straight bar on a high pulley and kneel facing away from the machine, gripping the bar overhead with palms down and hands about six inches apart.',
        'Keep your upper arms by your ears.',
        'Bend your elbows to let the bar drop behind your head, then extend your arms to press it back overhead until locked.',
      ],
      formChecks: [
        'Pin your upper arms by your ears',
        'Let the bar drop behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=G9ywYcdIIBM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Cable_Triceps_Extension/0.jpg',
    ),
    'Low_Cable_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Lie face up on the bench of a low cable row with your head pointing toward the rope attachment.',
        'Grab the rope ends with palms facing each other and arms extended over your face.',
        'Bend your elbows to lower the rope behind your head, then extend your arms back over your chest.',
      ],
      formChecks: [
        'Hold the rope over your face',
        'Lower behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NJScewjG7AI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Low_Cable_Triceps_Extension/0.jpg',
    ),
    'Lying_Close-Grip_Barbell_Triceps_Extension_Behind_The_Head': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench with your head near the end, holding a barbell with a overhand shoulder-width grip and arms extended over your chest.',
        'Lower the bar behind your head toward the floor by bending the elbows, then extend your arms back to the start.',
      ],
      formChecks: [
        'Lower behind your head toward the floor',
        'Hold a shoulder-width grip',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Ma_SNy-WjwU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Close-Grip_Barbell_Triceps_Extension_Behind_The_Head/0.jpg',
    ),
    'Lying_Close-Grip_Barbell_Triceps_Press_To_Chin': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench with your head off the end, holding an EZ bar with a overhand grip and arms extended over your chest.',
        'Lower the bar toward your chin by bending the elbows while keeping them from flaring, then press the bar back up until your arms are straight.',
      ],
      formChecks: [
        'Aim the bar at your chin',
        'Stop your elbows from flaring',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EkLv3kFPxmY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Close-Grip_Barbell_Triceps_Press_To_Chin/0.jpg',
    ),
    'Lying_Dumbbell_Tricep_Extension': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench holding two dumbbells over your chest with arms extended and palms facing each other.',
        'Keep your elbows tucked in.',
        'Lower the dumbbells toward your forehead by bending the elbows, then extend your arms back up until straight.',
      ],
      formChecks: [
        'Palms face each other',
        'Lower toward your forehead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=2XDPNh7a8p8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Dumbbell_Tricep_Extension/0.jpg',
    ),
    'Lying_Triceps_Press': ExerciseCoaching(
      howTo: [
        'Lie on a bench holding the bar over the chest with a close grip and elbows fixed.',
        'Lower toward the forehead, then press back to extension using the triceps.',
      ],
      formChecks: [
        'Elbows stay in, don\'t flare',
        'Only the forearms move',
        'Control the descent',
        'Keep the wrists neutral',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=s3NBb2O01WI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Triceps_Press/0.jpg',
    ),
    'Machine_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Adjust the seat and set your upper arms against the pads, grasping the handles.',
        'Extend your elbows to push the handles down until your arms are straight.',
        'Return under control until your elbows are bent, keeping your upper arms on the pads.',
      ],
      formChecks: [
        'Keep upper arms on the pads',
        'Push down to straight arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Bx8ga1BLHLE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Triceps_Extension/0.jpg',
    ),
    'One_Arm_Pronated_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench holding a dumbbell in one hand at arm\'s length, the arm perpendicular to your body and palm facing your feet.',
        'Lower the dumbbell toward your forehead by bending the elbow while keeping the upper arm still, then extend your arm back up to the top.',
      ],
      formChecks: [
        'Point your palm toward your feet',
        'Lower to your forehead, upper arm still',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=E4tHp4WRP70',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Pronated_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'One_Arm_Supinated_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Lie flat on a bench and press a dumbbell straight up in one hand, palm facing your face.',
        'Keep the upper arm vertical and bend only at the elbow to lower the weight toward your shoulder.',
        'Straighten the arm to drive it back up to lockout.',
      ],
      formChecks: [
        'Point the upper arm straight up',
        'Keep your palm facing your face',
        'Lower toward your shoulder',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0SfJvAJMc70',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Supinated_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Pin_Presses': ExerciseCoaching(
      howTo: [
        'Set a bench in a power rack with the safety pins at your chosen height.',
        'Lie back and grip the barbell resting on the pins just above your chest.',
        'Press it from a dead stop to full lockout, then lower it to settle on the pins before each rep.',
      ],
      formChecks: [
        'Start each rep from a dead stop',
        'Tuck your elbows in',
        'Drive to full lockout',
        'Settle the bar on the pins',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vkGUxdTr7so',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pin_Presses/0.jpg',
    ),
    'Reverse_Grip_Triceps_Pushdown': ExerciseCoaching(
      howTo: [
        'Set a straight bar on a high pulley and grip it palms-up at shoulder width.',
        'Keep your elbows pinned to your sides and push the bar down until your arms are fully extended.',
        'Let it rise back to chest level under control.',
      ],
      formChecks: [
        'Keep your palms facing up',
        'Pin your elbows to your sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Q1_WXKQV8aE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Grip_Triceps_Pushdown/0.jpg',
    ),
    'Seated_Bent-Over_One-Arm_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Sit at the end of a flat bench with a dumbbell in one hand, palm facing in.',
        'Hinge forward at the waist with a flat back and tuck the upper arm against your side.',
        'Straighten the elbow to drive the weight back until the arm is level, then lower.',
      ],
      formChecks: [
        'Hinge forward with a flat back',
        'Tuck the upper arm to your side',
        'Extend until the arm is level',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dSdryrEnoSo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Bent-Over_One-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Seated_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Sit at the end of a flat bench with a dumbbell in each hand, palms facing in.',
        'Hinge forward at the waist with a flat back and tuck both upper arms against your sides.',
        'Straighten the elbows to drive the weights back until your arms are level, then lower.',
      ],
      formChecks: [
        'Pin both upper arms to your sides',
        'Straighten both arms to level',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dSdryrEnoSo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Seated_Triceps_Press': ExerciseCoaching(
      howTo: [
        'Sit on a bench with back support and hold one dumbbell overhead with both hands, arms locked out.',
        'Keep your elbows pointing forward and lower the weight behind your head by bending the elbows.',
        'Press it back up to full extension.',
      ],
      formChecks: [
        'Point your elbows forward, not out',
        'Lower behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YK6zrgVI4GI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Triceps_Press/0.jpg',
    ),
    'Sled_Overhead_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Attach dual handles to a loaded sled and face away from it, stepping out until the line is tight.',
        'Raise your hands overhead with palms facing each other and elbows bent.',
        'Straighten your arms to full extension to drag the sled, then let the elbows bend back.',
      ],
      formChecks: [
        'Step out until the line is tight',
        'Keep your upper arms by your ears',
        'Extend hard to drag the sled',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1QI0tFgBuj4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Overhead_Triceps_Extension/0.jpg',
    ),
    'Speed_Band_Overhead_Triceps': ExerciseCoaching(
      howTo: [
        'Anchor a band at floor level and face away from it.',
        'Grab the band and bring your hands behind your head with elbows bent and high.',
        'Explosively straighten your arms overhead to lockout, then lower under control back behind your head.',
      ],
      formChecks: [
        'Explode to full lockout',
        'Keep your elbows high and tight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=blWRg-eS5fY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Speed_Band_Overhead_Triceps/0.jpg',
    ),
    'Standing_Bent-Over_One-Arm_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand holding a dumbbell in one hand with your palm facing in.',
        'Bend your knees slightly and hinge forward at the waist with a flat back until your torso is near parallel to the floor.',
        'Pin the upper arm to your side and straighten the elbow to drive the weight back, then lower.',
      ],
      formChecks: [
        'Hinge until your torso is near parallel',
        'Pin the upper arm to your side',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_TfW7qk8mbU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Bent-Over_One-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Standing_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand holding a dumbbell in each hand with palms facing in.',
        'Bend your knees slightly and hinge forward at the waist with a flat back until your torso is near parallel to the floor.',
        'Pin both upper arms to your sides and straighten the elbows to drive the weights back, then lower.',
      ],
      formChecks: [
        'Soft knees, hinge to near parallel',
        'Pin both upper arms to your sides',
        'Lock out the elbows behind you',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rqefaPkIPqc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Standing_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder width and hold one dumbbell overhead with both hands, arms extended.',
        'Keep your elbows in and pointing up as you lower the weight behind your head.',
        'Press back up to full lockout overhead.',
      ],
      formChecks: [
        'Keep your elbows pointing up',
        'Lower behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dsRbS_em7D8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Standing_Low-Pulley_One-Arm_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand with your back to a low pulley and grab the single handle in one hand.',
        'Bring it overhead until your arm is fully extended, elbow pointing up.',
        'Bend the elbow to lower the handle behind your head, then straighten the arm back to lockout.',
      ],
      formChecks: [
        'Keep the elbow pointing up',
        'Hold the upper arm still',
        'Stretch fully behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ZK6dMdPfe_Y',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Low-Pulley_One-Arm_Triceps_Extension/0.jpg',
    ),
    'Standing_One-Arm_Dumbbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder width and press a dumbbell overhead in one hand, arm fully extended with the pinky up.',
        'Keep your elbow pointing forward and lower the weight behind your head.',
        'Straighten the arm to press it back to lockout.',
      ],
      formChecks: [
        'Point your pinky up at the top',
        'Keep the elbow pointing forward',
        'Free hand braces the elbow',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=59l0fnZgQbw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_One-Arm_Dumbbell_Triceps_Extension/0.jpg',
    ),
    'Standing_Overhead_Barbell_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder width and hold a barbell overhead with a overhand grip, hands closer than shoulder width.',
        'Keep your elbows in and lower the bar behind your head by bending at the elbows.',
        'Extend your arms to press the bar back overhead to lockout.',
      ],
      formChecks: [
        'Grip inside shoulder width',
        'Keep your elbows tucked in',
        'Lower the bar behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=q5X9thiKofE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Overhead_Barbell_Triceps_Extension/0.jpg',
    ),
    'Standing_Towel_Triceps_Extension': ExerciseCoaching(
      howTo: [
        'Stand tall and hold one end of a towel with both hands, arms fully extended overhead and palms facing each other.',
        'Keep your elbows in and lower your hands behind your head by bending the elbows.',
        'Pull the towel taut for resistance as you extend back to lockout.',
      ],
      formChecks: [
        'Pull the towel taut for tension',
        'Lower your hands behind your head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fpmhCrrnP0M',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Towel_Triceps_Extension/0.jpg',
    ),
    'Tate_Press': ExerciseCoaching(
      howTo: [
        'Lie on a flat bench and press two dumbbells above your chest with palms facing forward and elbows flared out.',
        'Lower the weights by bending your elbows until the dumbbells nearly touch your upper chest, then extend your arms to squeeze the triceps at the top.',
      ],
      formChecks: [
        'Point elbows out wide',
        'Lower bells to your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Tq91KORBlFA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tate_Press/0.jpg',
    ),
    'Triceps_Pushdown': ExerciseCoaching(
      howTo: [
        'Stand at a high pulley with the elbows pinned to the sides.',
        'Extend the arms fully down, then return under control without letting the elbows drift.',
      ],
      formChecks: [
        'Elbows stay pinned to the sides',
        'Full extension at the bottom',
        'Don\'t lean over the bar to push it',
        'Control the return',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6Fzep104f0s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Triceps_Pushdown/0.jpg',
    ),
    'Triceps_Pushdown_-_Rope_Attachment': ExerciseCoaching(
      howTo: [
        'Attach a rope to a high pulley and grip it with palms facing each other.',
        'Keep your upper arms pinned to your sides and lean the torso slightly forward.',
        'Push the rope down by extending your elbows and spread the ends apart at the bottom, then let it rise to chest height.',
      ],
      formChecks: [
        'Pin upper arms to sides',
        'Spread rope at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cHzjrHRv5gY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Triceps_Pushdown_-_Rope_Attachment/0.jpg',
    ),
    'Triceps_Pushdown_-_V-Bar_Attachment': ExerciseCoaching(
      howTo: [
        'Attach a V-bar to a high pulley and take an overhand grip at shoulder width.',
        'Keep your upper arms tight to your sides and torso upright with a slight lean.',
        'Push the bar down by fully extending your elbows, then let it rise back to chest height under control.',
      ],
      formChecks: [
        'Grip the bar overhand',
        'Straighten arms fully',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=whMAtRrYB-s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Triceps_Pushdown_-_V-Bar_Attachment/0.jpg',
    ),
    'Weighted_Bench_Dip': ExerciseCoaching(
      howTo: [
        'Grip the edge of a bench behind you with hands shoulder width and rest your heels on a second bench ahead.',
        'Set a weight plate on your thighs.',
        'Lower your hips toward the floor by bending your elbows to about 90 degrees, then press through your palms to straighten your arms.',
      ],
      formChecks: [
        'Point elbows straight back',
        'Bend to 90 degrees',
        'Keep hips close to bench',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HEeT2sbmcXc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Bench_Dip/0.jpg',
    ),
    'Barbell_Lunge': ExerciseCoaching(
      howTo: [
        'With the bar on the upper back, step forward and lower until the back knee is just off the floor and the front thigh is parallel.',
        'Drive through the front heel back to standing.',
      ],
      formChecks: [
        'Torso upright, core braced',
        'Front knee stays over the foot, not past the toes',
        'Drive through the front heel',
        'Control the descent, don\'t drop',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7LWvWiMLS3M',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Lunge/0.jpg',
    ),
    'Barbell_Walking_Lunge': ExerciseCoaching(
      howTo: [
        'With the bar on the upper back, step forward into a lunge, then drive through the front heel and step straight into the next lunge, alternating legs.',
      ],
      formChecks: [
        'Stay tall, brace the core',
        'Long enough step to keep the knee over the foot',
        'Push through the front heel',
        'Control each step, no wobble',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XJyUHKWKnxc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Walking_Lunge/0.jpg',
    ),
    'Bodyweight_Walking_Lunge': ExerciseCoaching(
      howTo: [
        'Stand tall with feet shoulder width and hands on your hips.',
        'Step forward with one leg and bend both knees to drop your hips until the rear knee nearly touches the floor.',
        'Drive through the front heel to stand, then step forward into the next lunge with the other leg.',
      ],
      formChecks: [
        'Rear knee to the floor',
        'Drive through front heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lgDJ7x3834Y',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Walking_Lunge/0.jpg',
    ),
    'Dumbbell_Lunges': ExerciseCoaching(
      howTo: [
        'Stand tall holding a dumbbell in each hand at your sides.',
        'Step forward with one leg and lower your hips until both knees bend near 90 degrees and the rear knee nearly touches the floor.',
        'Push through the front heel to return, then repeat stepping with the other leg.',
      ],
      formChecks: [
        'Both knees to 90 degrees',
        'Keep chest tall over hips',
        'Drive through front heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eFWCn5iEbTU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Lunges/0.jpg',
    ),
    'Dumbbell_Rear_Lunge': ExerciseCoaching(
      howTo: [
        'Stand tall holding a dumbbell in each hand at your sides.',
        'Step backward with one leg and lower your hips until both knees bend near 90 degrees and the back knee nearly touches the floor.',
        'Drive through the front heel back to standing, then alternate legs.',
      ],
      formChecks: [
        'Step straight back',
        'Keep weight on front heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=uEA0D59JYvk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Rear_Lunge/0.jpg',
    ),
    'Elevated_Back_Lunge': ExerciseCoaching(
      howTo: [
        'Rack a barbell across your upper back and stand on a low raised platform with both feet.',
        'Step one foot back and down off the platform, lowering until the rear knee nears the floor and the front knee bends deeply.',
        'Drive through the front heel to return to the top.',
      ],
      formChecks: [
        'Step back off the platform',
        'Sink into a deep stretch',
        'Keep chest up under bar',
        'Drive through front heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=U8O40vangSQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elevated_Back_Lunge/0.jpg',
    ),
    'Kettlebell_Turkish_Get-Up_Lunge_style': ExerciseCoaching(
      howTo: [
        'Lie on your back and press a kettlebell straight up with one arm, locking the elbow.',
        'Roll onto your opposite forearm then hand, sweep your leg back into a lunge, and stand up while keeping the bell locked overhead.',
        'Reverse each step to lower back to the floor.',
      ],
      formChecks: [
        'Keep arm locked overhead',
        'Eyes on the bell',
        'Roll up onto your hand',
        'Sweep leg into lunge',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=87jrGmziYFk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Turkish_Get-Up_Lunge_style/0.jpg',
    ),
    'Lunge_Pass_Through': ExerciseCoaching(
      howTo: [
        'Stand holding a kettlebell in one hand.',
        'Step forward into a lunge, bending the front hip and knee while keeping your torso upright and back flat.',
        'At the bottom, pass the kettlebell under your front thigh to the other hand, then drive up and step through to switch legs.',
      ],
      formChecks: [
        'Hinge at the front hip',
        'Keep your back flat',
        'Pass bell under front thigh',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=tpJ09mGWZos',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lunge_Pass_Through/0.jpg',
    ),
    'Lunge_Sprint': ExerciseCoaching(
      howTo: [
        'Rack a Smith machine bar across your upper back and split your stance with one foot forward and one back.',
        'Lower into a lunge by bending both knees, then drive up explosively through the front heel.',
        'Repeat with speed while keeping your chest tall and movement controlled.',
      ],
      formChecks: [
        'Drive up explosively',
        'Keep your chest tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=c0AVozbLZFQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lunge_Sprint/0.jpg',
    ),
    'Step-up_with_Knee_Raise': ExerciseCoaching(
      howTo: [
        'Place one full foot on a box, drive through that heel to stand up onto it, and raise the opposite knee.',
        'Step back down under control and repeat.',
      ],
      formChecks: [
        'Whole foot on the box, drive through the heel',
        'Stand up with the working leg, don\'t push off the floor',
        'Control the way down',
        'Keep the torso tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=31sl6rqgWXs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Step-up_with_Knee_Raise/0.jpg',
    ),
    'Bottoms-Up_Clean_From_The_Hang_Position': ExerciseCoaching(
      howTo: [
        'Stand holding a kettlebell in one hand at hang position between your thighs.',
        'Hinge and swing it back, then snap your hips to drive it upward.',
        'Crush the handle hard and guide the bell to your shoulder, catching it balanced upside down with your elbow tucked in.',
      ],
      formChecks: [
        'Drive with a hip snap',
        'Crush the handle hard',
        'Stack wrist under the bell',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zO0uob2rhSE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bottoms-Up_Clean_From_The_Hang_Position/0.jpg',
    ),
    'Clean': ExerciseCoaching(
      howTo: [
        'Set up over a barbell with an overhand grip just outside your legs, hips down, back flat and chest up.',
        'Drive through the floor and extend your hips explosively, pulling the bar up your body.',
        'Shrug and drop under it to catch the bar racked on your shoulders.',
      ],
      formChecks: [
        'Flat back off the floor',
        'Bar brushes your thighs',
        'Explode through the hips',
        'Drop under to catch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=21qTUlicEHI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean/0.jpg',
    ),
    'Clean_Pull': ExerciseCoaching(
      howTo: [
        'Set up over a barbell with an overhand or hook grip just outside your legs, hips down, back flat and chest up.',
        'Push through the floor to lift the bar past your knees, then extend your hips, knees and ankles explosively.',
        'Shrug tall and let the bar rise without catching it.',
      ],
      formChecks: [
        'Keep the bar close',
        'Full extend the hips, knees and ankles',
        'No early arm pull',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=wZN6qYDUVuY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_Pull/0.jpg',
    ),
    'Clean_and_Jerk': ExerciseCoaching(
      howTo: [
        'Clean the bar to the shoulders, then dip slightly and drive it overhead with the legs, splitting or squatting under to catch it locked out.',
        'Stand to finish.',
      ],
      formChecks: [
        'Full hip extension on both the clean and the jerk',
        'Drive the jerk with the legs, not the arms',
        'Punch under a locked-out bar',
        'Recover with control, feet in line',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zXs5KQMhsEg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_and_Jerk/0.jpg',
    ),
    'Clean_and_Press': ExerciseCoaching(
      howTo: [
        'Set up over a barbell with a overhand grip slightly wider than shoulder width, hips down and back flat.',
        'Explosively extend your hips to clean the bar to your shoulders.',
        'Brace your core and press the bar overhead until your arms lock out, then lower it back to your shoulders.',
      ],
      formChecks: [
        'Explode hips to clean',
        'Catch in the front rack',
        'Brace before pressing',
        'Lock out overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KCe8l86-alA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_and_Press/0.jpg',
    ),
    'Clean_from_Blocks': ExerciseCoaching(
      howTo: [
        'Set the barbell on blocks at the desired height and grip just outside your legs.',
        'Sit your hips down over the heels with a flat back, chest up, and shoulders slightly ahead of the bar.',
        'Explode up by extending hips and knees, pull under, and catch in a front-rack squat.',
      ],
      formChecks: [
        'Set hips over the heels, chest up',
        'Drive off the blocks to full extension',
        'Pull under into a deep front rack',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AgIhE0E-PLU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Clean_from_Blocks/0.jpg',
    ),
    'Double_Kettlebell_Alternating_Hang_Clean': ExerciseCoaching(
      howTo: [
        'Set two kettlebells between your feet, push your hips back, and clean one to your shoulder while the other hangs.',
        'In one fluid motion, lower the racked bell to the hang as you snap your hips to clean the low bell up.',
        'Keep the bells swapping each rep.',
      ],
      formChecks: [
        'Hinge the hips to load',
        'Swap the bells in one motion',
        'Tame the arc into each rack',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JX64eQ4Ffq4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Alternating_Hang_Clean/0.jpg',
    ),
    'Double_Kettlebell_Snatch': ExerciseCoaching(
      howTo: [
        'Set two kettlebells behind your feet, bend the knees, and sit back to grip them.',
        'Swing both bells between your legs, then drive hard through the hips and punch them straight overhead to lockout in one motion.',
      ],
      formChecks: [
        'Drive hard through the hips',
        'Punch both bells to lockout',
        'Stack the bells over the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=p7Evs2D5aZc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Snatch/0.jpg',
    ),
    'Hang_Clean': ExerciseCoaching(
      howTo: [
        'Hold the bar at mid-thigh with a shoulder-width overhand or hook grip, back flat and torso leaning slightly forward.',
        'Aggressively extend the hips, knees, and ankles, then pull under the bar and catch it in a front-rack squat.',
      ],
      formChecks: [
        'Lean the torso slightly over the bar',
        'Triple-extend explosively',
        'Keep the bar brushing the thighs',
        'Snap elbows into the front rack',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WCdhjfg7fv4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Clean/0.jpg',
    ),
    'Hang_Clean_-_Below_the_Knees': ExerciseCoaching(
      howTo: [
        'Hold the bar just below the knees with a shoulder-width overhand or hook grip, back flat and chest up.',
        'Drive through the legs and snap the hips to full extension, then pull under and catch the bar in a front-rack squat.',
      ],
      formChecks: [
        'Keep the back flat off the start',
        'Snap the hips to full extension',
        'Catch in a deep front-rack squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KzCB9mc6J2w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Clean_-_Below_the_Knees/0.jpg',
    ),
    'Hang_Snatch': ExerciseCoaching(
      howTo: [
        'Take a wide overhand or hook grip with the bar at the hips, feet under the hips and turned out, spine extended and chest up.',
        'Violently extend the hips, knees, and ankles, then pull under and catch the bar overhead in a squat.',
      ],
      formChecks: [
        'Take a wide grip at the hips',
        'Keep the bar close on the pull',
        'Extend hips, knees, and ankles',
        'Punch under to lockout in a squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zxdfWgksUZY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Snatch/0.jpg',
    ),
    'Hang_Snatch_-_Below_Knees': ExerciseCoaching(
      howTo: [
        'Take a wide overhand or hook grip with the bar just below the knees, feet under the hips and torso leaning forward.',
        'Explode through the hips to full extension, then pull yourself under and lock the bar out overhead in a squat.',
      ],
      formChecks: [
        'Keep the chest up off the knees',
        'Finish the pull tall',
        'Lock out over a deep squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZ2olIu6Hao',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hang_Snatch_-_Below_Knees/0.jpg',
    ),
    'Heaving_Snatch_Balance': ExerciseCoaching(
      howTo: [
        'Rest a light bar across the back of your shoulders with a wide snatch grip, feet just wider than hips and turned out.',
        'Dip the knees, then explosively drive the bar up and drop under it, catching it locked out overhead in a full squat.',
      ],
      formChecks: [
        'Dip straight down with the legs',
        'Drive the bar off the shoulders',
        'Drop fast into a full squat',
        'Lock out before the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VCYa3N9Qb4o',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Heaving_Snatch_Balance/0.jpg',
    ),
    'Kettlebell_Dead_Clean': ExerciseCoaching(
      howTo: [
        'Set a kettlebell between your feet, push your hips back, and grip it with eyes forward.',
        'Extend through the legs and hips to pull the bell up, guiding it around the wrist to rack at the shoulder.',
        'Lower it back to the floor to reset each rep.',
      ],
      formChecks: [
        'Dead-stop the bell every rep',
        'Guide it around the wrist to rack',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6Hjuscd4ab4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Dead_Clean/0.jpg',
    ),
    'Kettlebell_Hang_Clean': ExerciseCoaching(
      howTo: [
        'Hold a kettlebell at a hang with your hips pushed back and eyes forward.',
        'Extend through the legs and hips to pull the bell up, rotating your hand around it to catch softly in the rack.',
        'Lower back to the hang to begin the next rep.',
      ],
      formChecks: [
        'Hinge to load the hips',
        'Rotate the hand for a soft rack',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Z8zvgkiFmNQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Hang_Clean/0.jpg',
    ),
    'Muscle_Snatch': ExerciseCoaching(
      howTo: [
        'Hold the loaded bar at mid-thigh with a wide grip, hips low, chest up, and head forward.',
        'Explosively extend the hips and pull the bar upward, keeping it close, then punch it to lockout overhead without dropping under it.',
      ],
      formChecks: [
        'Stay tall with no dip under',
        'Turn the wrists over fast',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9Ze3-UiuRT0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Muscle_Snatch/0.jpg',
    ),
    'One-Arm_Kettlebell_Clean': ExerciseCoaching(
      howTo: [
        'Place a kettlebell between your feet, push your hips back, and grip it one-handed with eyes forward.',
        'Extend through the legs and hips to pull the bell up, rotating your hand around it to catch cleanly at the shoulder.',
        'Lower and repeat.',
      ],
      formChecks: [
        'Keep the bell tight to the body',
        'Wrap the rack, don\'t bang it',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rxv0d1ZOq3c',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Clean/0.jpg',
    ),
    'One-Arm_Kettlebell_Clean_and_Jerk': ExerciseCoaching(
      howTo: [
        'Clean the kettlebell to your shoulder by extending through the legs and hips, rotating the palm to face forward.',
        'Dip the knees, then drive hard and punch the bell to lockout overhead, catching it with a slight knee bend.',
      ],
      formChecks: [
        'Rotate the palm on the clean',
        'Dip and drive from the legs',
        'Punch the bell to lockout',
        'Catch with a soft knee bend',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aFvMpEEDtOk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Clean_and_Jerk/0.jpg',
    ),
    'One-Arm_Kettlebell_Snatch': ExerciseCoaching(
      howTo: [
        'Set a kettlebell between your feet, bend the knees, and sit the hips back with eyes forward.',
        'Swing the bell back between your legs, then reverse hard and drive through the hips to punch it straight to lockout overhead in one motion.',
      ],
      formChecks: [
        'Drive the swing with the hips',
        'Keep the bell close on the way up',
        'Spear the hand through at lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6l2Iu26oWW8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Snatch/0.jpg',
    ),
    'One-Arm_Kettlebell_Split_Snatch': ExerciseCoaching(
      howTo: [
        'Hold a kettlebell in one hand and squat toward the floor.',
        'Reverse the motion by extending the hips, knees, then ankles to send the bell overhead, and drop into a split lunge as you lock it out.',
        'Recover to standing.',
      ],
      formChecks: [
        'Extend fully before you split',
        'Punch straight to overhead lockout',
        'Drop into a front-back split',
        'Stabilize with the arm locked',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Fv3A5RM0J5E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Split_Snatch/0.jpg',
    ),
    'One-Arm_Open_Palm_Kettlebell_Clean': ExerciseCoaching(
      howTo: [
        'Set one kettlebell between your feet and hinge down to grip the handle with one hand.',
        'Drive through your hips and hamstrings to pull it up fast, opening the hand so the bell flips and the ball settles into your open palm at shoulder height.',
        'Lower it back down between your feet.',
      ],
      formChecks: [
        'Snap the hips to launch it',
        'Open the palm as it flips',
        'Keep the bell close in',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nGOefsEHQD0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Open_Palm_Kettlebell_Clean/0.jpg',
    ),
    'Open_Palm_Kettlebell_Clean': ExerciseCoaching(
      howTo: [
        'Straddle one kettlebell and hinge down to grasp the handle.',
        'Extend explosively through your legs and hips to send it up toward your shoulder, then release your grip so the bell flips and the ball rests in your open palm.',
        'Lower it back between your feet under control.',
      ],
      formChecks: [
        'Extend legs and hips together',
        'Relax grip, cushion the catch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rvd7DHxXXjM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Open_Palm_Kettlebell_Clean/0.jpg',
    ),
    'Power_Clean': ExerciseCoaching(
      howTo: [
        'From a deadlift setup, pull the bar explosively past the knees, extend the hips, ankles and knees, then whip the elbows through to catch the bar on the front of the shoulders in a partial squat.',
      ],
      formChecks: [
        'Keep the bar close to the body',
        'Explode through the hips, knees and ankles',
        'Fast elbows to rack the bar',
        'Catch soft in a quarter squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=e8TpDdMYq4Y',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Clean/0.jpg',
    ),
    'Power_Clean_from_Blocks': ExerciseCoaching(
      howTo: [
        'Set the bar on blocks and take a grip just outside your legs, hips down, back flat, shoulders over the bar.',
        'Drive through your heels and snap your hips through to accelerate the bar upward.',
        'Pull under and catch it on your front shoulders in a quarter squat, then stand tall.',
      ],
      formChecks: [
        'Shoulders over the bar',
        'Push the floor away',
        'Snap the hips violently',
        'Catch with elbows high',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ztNOYTwnqjE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Clean_from_Blocks/0.jpg',
    ),
    'Power_Snatch': ExerciseCoaching(
      howTo: [
        'Stand over the bar with a wide grip, feet under your hips, hips down and chest up.',
        'Pull the bar from the floor and accelerate it past your hips with a powerful snap of the hips and knees.',
        'Pull yourself under and catch it locked out overhead in a partial squat, then stand.',
      ],
      formChecks: [
        'Wide grip, bar brushing close',
        'Accelerate past the hips',
        'Full snap of hips and knees',
        'Punch under to lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=z1j2QMBJF6c',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Snatch/0.jpg',
    ),
    'Power_Snatch_from_Blocks': ExerciseCoaching(
      howTo: [
        'Set the bar on blocks and take a wide grip, feet under your hips, hips down with chest up.',
        'Drive hard through your legs to explode the bar upward, extending fully.',
        'Pull under quickly and receive it locked overhead in a partial squat, then push through your quads to stand.',
      ],
      formChecks: [
        'Drive hard through the legs',
        'Extend tall, then pull under',
        'Catch locked above parallel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=su5f3Txs658',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Snatch_from_Blocks/0.jpg',
    ),
    'Rack_Delivery': ExerciseCoaching(
      howTo: [
        'Hold the bar in the scarecrow position with your upper arms parallel to the floor and forearms hanging down.',
        'Whip your elbows down and around fast to rotate your hands under the bar and deliver it onto the front of your shoulders.',
        'Meet it in a quarter squat with elbows high, then stand.',
      ],
      formChecks: [
        'Whip the elbows around fast',
        'Meet it high on the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WxjRfBe4Uv0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rack_Delivery/0.jpg',
    ),
    'Smith_Machine_Hang_Power_Clean': ExerciseCoaching(
      howTo: [
        'Unhook the loaded Smith bar at knee height with a overhand grip just outside your shoulders, arms straight, chest up.',
        'Hinge slightly then drive through your hips and hamstrings to explode the bar upward along the track.',
        'Shrug and pull under, catching it on your front shoulders in a partial squat.',
      ],
      formChecks: [
        'Start from the knee hang',
        'Explode straight up the track',
        'Whip the elbows under fast',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YjxK7RppzIM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Hang_Power_Clean/0.jpg',
    ),
    'Snatch': ExerciseCoaching(
      howTo: [
        'From a wide grip, pull the bar explosively from the floor, extend the hips and pull under to catch it overhead in a full squat, then stand to lockout.',
      ],
      formChecks: [
        'Wide grip, bar close and over the mid-foot',
        'Explode through the hips',
        'Pull under fast to a locked-out catch',
        'Stay tight and stand tall to finish',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Iy0vPROslAA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch/0.jpg',
    ),
    'Snatch_Balance': ExerciseCoaching(
      howTo: [
        'Rack the bar across your back with a wide snatch grip and feet in the pulling position.',
        'Dip and drive sharply with your knees to pop the bar off your shoulders.',
        'Drop aggressively under it into a deep overhead squat, locking your arms out, then push through your quads to stand tall.',
      ],
      formChecks: [
        'Sharp dip and knee drive',
        'Pop the bar off the back',
        'Drop fast into a deep squat',
        'Lock the arms overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XuFaD1sAVGI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Balance/0.jpg',
    ),
    'Snatch_Pull': ExerciseCoaching(
      howTo: [
        'Set up over the bar with a wide snatch grip, hips down, back flat, shoulders just ahead of the bar.',
        'Pull the bar off the floor by pushing through your heels, keeping it close as it passes your knees.',
        'Finish with a violent extension of your hips and hamstrings and a shrug, then lower under control.',
      ],
      formChecks: [
        'Sweep it back past the knees',
        'Extend tall and shrug hard',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AYK4EFtQDV8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_Pull/0.jpg',
    ),
    'Snatch_from_Blocks': ExerciseCoaching(
      howTo: [
        'Set the bar on blocks and take a wide grip, feet under your hips, hips down and chest up.',
        'Pull from the blocks and extend explosively through your legs and hips.',
        'Pull yourself under the bar and receive it locked out overhead in a full squat, then drive through your quads to stand.',
      ],
      formChecks: [
        'Explode then pull under fast',
        'Receive deep in a full squat',
        'Stand up through the quads',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CdMjz2A4Vs0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Snatch_from_Blocks/0.jpg',
    ),
    'Split_Clean': ExerciseCoaching(
      howTo: [
        'Set up over the bar with an overhand grip just outside your legs, hips down and chest up.',
        'Pull from the floor and extend hard through your legs and hips.',
        'Drop under by splitting one foot forward and one back, catching the bar on your front shoulders, then step your feet together to stand.',
      ],
      formChecks: [
        'Extend fully before the split',
        'Split one foot front, one back',
        'Catch on the front shoulders',
        'Front shin stays vertical',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=a5CR3Bi2Gc8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Clean/0.jpg',
    ),
    'Split_Snatch': ExerciseCoaching(
      howTo: [
        'Stand over the bar with a wide grip, feet under your hips, hips down and chest up.',
        'Pull the bar from the floor and drive through your hips and hamstrings to full extension.',
        'Drop under by splitting one foot forward and one back, catching it locked out overhead, then recover your feet to stand.',
      ],
      formChecks: [
        'Drive to full hip extension',
        'Split the feet to drop under',
        'Catch locked overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VFdCGK8yk-8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Snatch/0.jpg',
    ),
    'Two-Arm_Kettlebell_Clean': ExerciseCoaching(
      howTo: [
        'Set two kettlebells between your feet and hinge back with your chest up, one handle in each hand.',
        'Extend through your legs and hips to drive the bells up, then guide your hands around and under so each bell racks against the front of your shoulders.',
        'Lower them back down under control.',
      ],
      formChecks: [
        'Hinge back, don\'t squat down',
        'Guide the bells around, not up',
        'Rack soft on the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ve3HiSIfguk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Clean/0.jpg',
    ),
    'Alternate_Leg_Diagonal_Bound': ExerciseCoaching(
      howTo: [
        'Stand with one foot slightly ahead of the other.',
        'Push off explosively from the front leg and drive the opposite knee up and forward, bounding diagonally across your body.',
        'Land on the opposite foot and immediately spring off it in the other diagonal direction, alternating legs each bound.',
      ],
      formChecks: [
        'Drive the knee up and across',
        'Land and spring off instantly',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9eonoveQ3Vo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternate_Leg_Diagonal_Bound/0.jpg',
    ),
    'Backward_Medicine_Ball_Throw': ExerciseCoaching(
      howTo: [
        'Stand holding a medicine ball down in front of you with both hands, feet shoulder-width.',
        'Dip into a quarter squat and let the ball swing down between your legs.',
        'Explode up through your hips and legs and swing your arms overhead to hurl the ball up and back behind you.',
      ],
      formChecks: [
        'Swing the ball down between the legs',
        'Explode up and release back overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fU1O_5bfFXY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Backward_Medicine_Ball_Throw/0.jpg',
    ),
    'Bench_Jump': ExerciseCoaching(
      howTo: [
        'Stand a foot or two from a low bench, feet shoulder-width.',
        'Drop into a short squat and swing your arms back, then explode up, extending the hips, knees, and ankles to jump over the bench and land with knees bent.',
        'Turn around and jump back over.',
      ],
      formChecks: [
        'Fully extend hips on takeoff',
        'Clear the bench cleanly',
        'Land soft, knees bent',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cjePrG4E-24',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Jump/0.jpg',
    ),
    'Bench_Sprint': ExerciseCoaching(
      howTo: [
        'Stand tall with one foot planted on top of a bench, heel near the edge.',
        'Drive down through that foot, extending the hip and knee to spring up, and switch feet in the air so the opposite foot lands on the bench.',
        'Move quickly and stay upright.',
      ],
      formChecks: [
        'Drive down through the top foot',
        'Switch feet in the air',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fC4GiRdITqE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Sprint/0.jpg',
    ),
    'Box_Jump_Multiple_Response': ExerciseCoaching(
      howTo: [
        'Face the box about an arm\'s length away with knees slightly bent and arms low.',
        'Swing the arms and jump up and forward off both feet, driving through the hips to land flat-footed on top.',
        'Step down and immediately rebound into the next jump.',
      ],
      formChecks: [
        'Swing arms and drive the hips',
        'Land flat-footed on top',
        'Rebound with minimal contact',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6rKLTV2Y618',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Jump_Multiple_Response/0.jpg',
    ),
    'Box_Skip': ExerciseCoaching(
      howTo: [
        'Set boxes in a line and face the first with one leg slightly back.',
        'Drive powerfully off the back leg, pushing the hips high, and land on top of the box with the lead foot.',
        'Skip off and up onto each following box in a rhythmic bound.',
      ],
      formChecks: [
        'Explode off the back leg',
        'Push the hips high',
        'Land lead foot on the box',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Lt-779NpGuo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Skip/0.jpg',
    ),
    'Carioca_Quick_Step': ExerciseCoaching(
      howTo: [
        'Stand tall with your feet a few inches apart and move to the side.',
        'Quick-step one foot behind the other and pull that knee straight up, firing your arms as the knee rises.',
        'Keep your feet from twisting and your eyes forward as you go.',
      ],
      formChecks: [
        'Cross one foot behind',
        'Pull the knee straight up',
        'Keep feet square, eyes ahead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XEw2SLBP-oE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Carioca_Quick_Step/0.jpg',
    ),
    'Catch_and_Overhead_Throw': ExerciseCoaching(
      howTo: [
        'Stand facing a wall or partner holding a medicine ball.',
        'Take the ball overhead and behind your head, stretching tall, then snap it forward hard using the lats and core to launch it.',
        'Catch the rebound and load straight into the next throw.',
      ],
      formChecks: [
        'Reach the ball overhead and back',
        'Snap it forward with the lats',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AXwrxkYjJWQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Catch_and_Overhead_Throw/0.jpg',
    ),
    'Chest_Push_multiple_response': ExerciseCoaching(
      howTo: [
        'Kneel tall facing a wall or partner with a medicine ball held tight to your chest.',
        'Explode the hips forward and push the ball out hard from your chest, letting yourself fall forward to catch on your hands.',
        'Pop back upright and repeat.',
      ],
      formChecks: [
        'Keep the ball tight to your chest',
        'Explode the hips forward',
        'Catch on your hands, pop up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zkEy0iWYaBY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_multiple_response/0.jpg',
    ),
    'Chest_Push_single_response': ExerciseCoaching(
      howTo: [
        'Kneel with a medicine ball pressed tight to your chest.',
        'Explode the hips forward and press the ball out with everything you have to throw it as far as possible.',
        'Let your body follow through and catch yourself on your hands.',
      ],
      formChecks: [
        'One all-out push for distance',
        'Catch your fall on both hands',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zkEy0iWYaBY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_single_response/0.jpg',
    ),
    'Chest_Push_from_3_point_stance': ExerciseCoaching(
      howTo: [
        'Set up in a three-point stance, squatted low with a flat back and one hand down beside the ball.',
        'Take your first step and scoop the ball to your chest with both hands, then explode forward and press it out powerfully at the target.',
      ],
      formChecks: [
        'Flat back in the stance',
        'Scoop the ball to your chest',
        'Explode forward off the step',
        'Push hard at the target',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=uxC1db4Ka_E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_from_3_point_stance/0.jpg',
    ),
    'Chest_Push_with_Run_Release': ExerciseCoaching(
      howTo: [
        'Start in an athletic stance with knees bent, hips back, and the medicine ball held low by your legs.',
        'Draw the ball to your chest on your first step, then explosively push it forward on the second step and sprint after it right away.',
      ],
      formChecks: [
        'Load the ball on step one',
        'Push hard on step two',
        'Release forward and up',
        'Sprint after the ball',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZzTcPlsOHo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chest_Push_with_Run_Release/0.jpg',
    ),
    'Depth_Jump_Leap': ExerciseCoaching(
      howTo: [
        'Stand on the lower box with feet together near the edge.',
        'Step off and drop to the ground, landing on both feet, then instantly rebound and leap up onto the taller box in one explosive motion.',
        'Spend as little time on the ground as possible.',
      ],
      formChecks: [
        'Step off, don\'t jump down',
        'Rebound the instant you land',
        'Stick the top box soft',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dkthVHrGYUI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Depth_Jump_Leap/0.jpg',
    ),
    'Double_Leg_Butt_Kick': ExerciseCoaching(
      howTo: [
        'Stand with knees slightly bent.',
        'Dip quickly into a short squat, then jump straight up for maximum height.',
        'At the top, snap both heels up toward your glutes by bending the knees, then extend the legs to land softly.',
      ],
      formChecks: [
        'Jump straight up for height',
        'Snap both heels to your glutes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cso1Bx3hToc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Leg_Butt_Kick/0.jpg',
    ),
    'Drop_Push': ExerciseCoaching(
      howTo: [
        'Set two low boxes or platforms two to three feet apart and take a pushup position between them, a hand on each box.',
        'Keeping good posture, press up off the boxes and bring your hands in to shoulder width, dropping to the floor between them.',
        'Absorb the landing softly through your arms.',
      ],
      formChecks: [
        'Press up and pull hands narrow',
        'Catch soft on the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IPhk99GMkSs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Drop_Push/0.jpg',
    ),
    'Dumbbell_Seated_Box_Jump': ExerciseCoaching(
      howTo: [
        'Sit on a bench facing a box with a dumbbell held to your chest in both hands and feet planted firmly.',
        'Lean your torso forward, then drive through both feet to explode up out of the seat and land softly on top of the box.',
        'Step back down.',
      ],
      formChecks: [
        'Lean your torso forward first',
        'Drive up through both feet',
        'Keep the dumbbell at your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NVQLEHdJlAw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Seated_Box_Jump/0.jpg',
    ),
    'Fast_Skipping': ExerciseCoaching(
      howTo: [
        'Start relaxed with one leg slightly forward.',
        'Skip forward using a quick step-hop rhythm, hopping on one foot then switching to the other with each stride.',
        'Keep the skips low and fast with rapid ground contacts and active arms.',
      ],
      formChecks: [
        'Quick, low ground contacts',
        'Skip fast and drive the arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=K6pY2r2_CoM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Fast_Skipping/0.jpg',
    ),
    'Freehand_Jump_Squat': ExerciseCoaching(
      howTo: [
        'Cross your arms over your chest and set your feet shoulder-width apart.',
        'Sink into a squat until your thighs reach parallel, then drive up explosively and jump off the floor.',
        'Land softly on the balls of your feet and absorb straight into the next jump.',
      ],
      formChecks: [
        'Sink to parallel',
        'Explode straight up',
        'Land soft, absorb into a squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3N_6lavLmSE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Freehand_Jump_Squat/0.jpg',
    ),
    'Front_Box_Jump': ExerciseCoaching(
      howTo: [
        'Set a box one to two feet in front of you and stand with feet shoulder-width apart.',
        'Dip into a short quarter squat and swing your arms back, then explode up and forward to land softly on top of the box.',
        'Absorb in a partial squat with knees soft, then step back down.',
      ],
      formChecks: [
        'Swing arms back then up',
        'Land in a squat on the box',
        'Step down, never jump down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=-eQ_JK5t3Lc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Box_Jump/0.jpg',
    ),
    'Front_Cone_Hops_or_hurdle_hops': ExerciseCoaching(
      howTo: [
        'Line up several cones a few feet apart and stand facing the first with feet shoulder-width.',
        'Jump over each cone with both feet, swinging your arms up to drive height.',
        'Land on the balls of your feet and rebound immediately over the next cone with minimal ground contact.',
      ],
      formChecks: [
        'Keep both feet together',
        'Quick, springy ground contact',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FXb-dUkGL5o',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Cone_Hops_or_hurdle_hops/0.jpg',
    ),
    'Heavy_Bag_Thrust': ExerciseCoaching(
      howTo: [
        'Stand tall beside the heavy bag with your feet staggered and wide, and place your hand on the bag at chest height.',
        'Twist through your waist and drive your hand forward to thrust the bag away explosively.',
        'Catch its return with a bent arm and absorb it into the next push.',
      ],
      formChecks: [
        'Twist through the hips',
        'Thrust the bag away hard',
        'Catch the rebound bent-armed',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4Dsy3pl6a5s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Heavy_Bag_Thrust/0.jpg',
    ),
    'Hurdle_Hops': ExerciseCoaching(
      howTo: [
        'Set up a row of hurdles a few feet apart and stand facing the first with feet shoulder-width.',
        'Jump over each hurdle with both feet, swinging your arms up for lift.',
        'Land softly on the balls of your feet and rebound straight into the next hurdle.',
      ],
      formChecks: [
        'Snap hips to clear each hurdle',
        'Minimal ground contact',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SuddHMMcK5I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hurdle_Hops/0.jpg',
    ),
    'Isometric_Chest_Squeezes': ExerciseCoaching(
      howTo: [
        'Stand or sit tall and bend both arms to ninety degrees, pressing your palms together in front of your chest with fingers pointing forward.',
        'Push your hands into each other as hard as you can and squeeze your chest.',
        'Hold the contraction, then ease off under control.',
      ],
      formChecks: [
        'Press palms together hard',
        'Elbows up at chest height',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=anxpxp0rbHs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Isometric_Chest_Squeezes/0.jpg',
    ),
    'Knee_Tuck_Jump': ExerciseCoaching(
      howTo: [
        'Stand with knees slightly bent and hold your palms down at chest height as a target.',
        'Dip into a quarter squat, then explode straight up and tuck both knees toward your hands.',
        'Land softly on the balls of your feet and sink into the next jump.',
      ],
      formChecks: [
        'Tuck knees to your hands',
        'Jump up, not forward',
        'Land light into the next',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vf3NGKY2JRU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Knee_Tuck_Jump/0.jpg',
    ),
    'Kneeling_Arm_Drill': ExerciseCoaching(
      howTo: [
        'Kneel with your left foot forward and right knee down, pressing through the front heel to keep your glutes tight.',
        'Drive your arms in a long running motion, swinging each hand from cheek to hip.',
        'Keep elbows bent around ninety degrees and move the arms fast and loose.',
      ],
      formChecks: [
        'Swing hand cheek to hip',
        'Keep elbows near ninety',
        'Tall torso, no twisting',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=-cqC7XFYIpk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Arm_Drill/0.jpg',
    ),
    'Kneeling_Jump_Squat': ExerciseCoaching(
      howTo: [
        'Kneel tall with a barbell racked across your shoulders and toes tucked under.',
        'Sit your hips back toward your heels to load, then explode up by snapping your hips forward.',
        'Land on both feet in a squat stance and absorb the drop softly through your knees and glutes.',
      ],
      formChecks: [
        'Sit hips back to your heels',
        'Snap hips to explode up',
        'Land both feet at once',
        'Absorb soft through the knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rAmqNguXyRQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Jump_Squat/0.jpg',
    ),
    'Lateral_Bound': ExerciseCoaching(
      howTo: [
        'Stand in a half squat with your body facing ninety degrees from your travel direction.',
        'Load your outside leg by shifting weight onto it, then push off explosively and bound sideways.',
        'Land on the opposite leg in a soft half squat, stick it, then bound back the other way.',
      ],
      formChecks: [
        'Load the outside leg',
        'Push off and bound sideways',
        'Stick the single-leg landing',
        'Hold before the next bound',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OYFKamK8Ts8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Bound/0.jpg',
    ),
    'Lateral_Box_Jump': ExerciseCoaching(
      howTo: [
        'Stand tall beside a short box with feet hip-width.',
        'Dip quickly into a quarter squat to load, then explode up and sideways to land on top of the box.',
        'Absorb softly in a partial squat with both feet, then step down and reset on the other side.',
      ],
      formChecks: [
        'Quick dip, jump sideways',
        'Land balanced on the box',
        'Step down, don\'t jump down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9TOUyNjB-kM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Box_Jump/0.jpg',
    ),
    'Lateral_Cone_Hops': ExerciseCoaching(
      howTo: [
        'Line up cones a few feet apart and stand at one end facing ninety degrees to the line.',
        'Dip your knees to load, then hop sideways over each cone with both feet together.',
        'Land softly on the balls of your feet and rebound immediately over the next cone.',
      ],
      formChecks: [
        'Hop sideways, feet together',
        'Absorb through the inner thighs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=viKgp6eLiLA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lateral_Cone_Hops/0.jpg',
    ),
    'Linear_3-Part_Start_Technique': ExerciseCoaching(
      howTo: [
        'Start with both feet on a line, then step your left toe back level with your right ankle to stagger your stance.',
        'Lean your weight forward over the front foot until you feel off balance.',
        'Drive your back leg forward and explode into a sprint, staying low through the first steps.',
      ],
      formChecks: [
        'Stagger feet on the line',
        'Lean till you lose balance',
        'Drive out low and hard',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Q--XFjVhDC0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Linear_3-Part_Start_Technique/0.jpg',
    ),
    'Linear_Acceleration_Wall_Drill': ExerciseCoaching(
      howTo: [
        'Lean into a wall at about forty-five degrees with your feet together and glutes squeezed tight.',
        'Drive one knee up quickly, pause at the top, then punch that foot straight down into the ground.',
        'Switch legs and keep alternating, holding a rigid line from heel to head.',
      ],
      formChecks: [
        'Straight line, heel to head',
        'Drive the knee up high',
        'Punch the foot straight down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=niTXjp1QMtk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Linear_Acceleration_Wall_Drill/0.jpg',
    ),
    'Linear_Depth_Jump': ExerciseCoaching(
      howTo: [
        'Stand on top of one box facing the second platform a few feet away.',
        'Step off and drop to the ground, landing softly on the balls of both feet with knees bent to absorb.',
        'The instant you land, explode straight up onto the second box, spending as little time on the ground as possible.',
      ],
      formChecks: [
        'Step off, don\'t jump off',
        'Minimize ground contact',
        'Explode up onto the next box',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HmNrqB9XXag',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Linear_Depth_Jump/0.jpg',
    ),
    'Medicine_Ball_Chest_Pass': ExerciseCoaching(
      howTo: [
        'Face a partner or wall holding a medicine ball at your chest, elbows tucked.',
        'Explosively press both arms forward to throw the ball straight from your chest.',
        'Catch the return, absorbing it back to chest level.',
      ],
      formChecks: [
        'Keep elbows tucked at chest',
        'Punch both arms straight out',
        'Soften hands to catch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nScUq9PEHWo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Medicine_Ball_Chest_Pass/0.jpg',
    ),
    'Medicine_Ball_Full_Twist': ExerciseCoaching(
      howTo: [
        'Stand back to back with a partner a couple feet apart, holding the ball at your trunk.',
        'Rotate through your torso to pass the ball to their hands on one side.',
        'Reverse and receive it on the other side, keeping hips turning with the shoulders.',
      ],
      formChecks: [
        'Rotate through the whole trunk',
        'Turn hips along with shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=BLfWZ1jn4-U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Medicine_Ball_Full_Twist/0.jpg',
    ),
    'Medicine_Ball_Scoop_Throw': ExerciseCoaching(
      howTo: [
        'Stand in a semisquat with a medicine ball hanging between your legs near your feet.',
        'Explode through your hips and legs, jumping up while swinging both arms to scoop the ball up and back over your head.',
        'Release at full extension.',
      ],
      formChecks: [
        'Start ball low between legs',
        'Drive hips and jump up',
        'Scoop up and back overhead',
        'Release at full stretch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8YuLIBpiZMQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Medicine_Ball_Scoop_Throw/0.jpg',
    ),
    'Mountain_Climbers': ExerciseCoaching(
      howTo: [
        'Start in a pushup position with hands under shoulders and one knee drawn up under your hip.',
        'Explosively switch leg positions, driving the back knee forward as the front leg extends.',
        'Keep alternating fast while holding a firm plank.',
      ],
      formChecks: [
        'Drive knee under your hip',
        'Keep hips low, don\'t pike',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kLh-uczlPLg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Mountain_Climbers/0.jpg',
    ),
    'Moving_Claw_Series': ExerciseCoaching(
      howTo: [
        'Move forward with a running action, flexing the knee to kick your heel toward your glutes as the hip extends.',
        'Reload the quad as the leg swings forward, then claw the ball of your foot down and back into the ground.',
        'Alternate legs with each stride.',
      ],
      formChecks: [
        'Snap heel toward your glute',
        'Claw the foot down and back',
        'Run tall and quick',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DE9s3y5mE7s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Moving_Claw_Series/0.jpg',
    ),
    'One-Arm_Medicine_Ball_Slam': ExerciseCoaching(
      howTo: [
        'Stand in a staggered stance holding a medicine ball in one hand on your back-leg side.',
        'Wind the arm up, raising the ball overhead.',
        'Slam it down hard in front of you, crunching through your abs and folding at the trunk.',
      ],
      formChecks: [
        'Wind the ball high overhead',
        'Slam down and across',
        'Crunch hard through the abs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IK8KA1TajU4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Medicine_Ball_Slam/0.jpg',
    ),
    'Overhead_Slam': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder-width holding a medicine ball in both hands.',
        'Raise the ball overhead and stretch your body tall.',
        'Slam it straight down to the floor with force, driving through your lats as you fold forward.',
      ],
      formChecks: [
        'Stretch tall overhead first',
        'Slam down through the lats',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YeguWbNhLfg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Overhead_Slam/0.jpg',
    ),
    'Quick_Leap': ExerciseCoaching(
      howTo: [
        'Stand facing a box a foot or two from its edge.',
        'Drive through your hips to hop up onto the box, landing softly on both feet with knees bent and feet flat.',
        'Step or hop back down and immediately repeat with quick, reactive jumps.',
      ],
      formChecks: [
        'Drive hips onto the box',
        'Land soft, feet flat',
        'Reset quick and repeat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zMOwSPJrSY0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Quick_Leap/0.jpg',
    ),
    'Return_Push_from_Stance': ExerciseCoaching(
      howTo: [
        'Set up in an athletic two- or three-point stance facing a partner.',
        'On the signal, burst into a catching position and take the medicine ball with both hands.',
        'Immediately push it straight back to your partner, driving through the shoulders.',
      ],
      formChecks: [
        'Burst from your stance',
        'Catch and push it straight back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=GtpCF3n_3Qw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Return_Push_from_Stance/0.jpg',
    ),
    'Rocket_Jump': ExerciseCoaching(
      howTo: [
        'Stand relaxed with feet shoulder-width and arms held close to your body.',
        'Dip into a half squat, then explode straight up as high as you can.',
        'Fully extend your body and reach overhead at the peak, then land softly into the next dip.',
      ],
      formChecks: [
        'Dip to a half squat',
        'Explode straight up tall',
        'Land soft into the next dip',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aE0kZsprudA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rocket_Jump/0.jpg',
    ),
    'Rope_Jumping': ExerciseCoaching(
      howTo: [
        'Hold a rope handle in each hand with the rope behind your heels.',
        'Turn it over your head with your wrists and hop over as it reaches the floor.',
        'Land softly on the balls of your feet and keep a steady, rhythmic turning pace.',
      ],
      formChecks: [
        'Turn the rope with your wrists',
        'Small hops on the balls of feet',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NkXDy8K-1jY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Jumping/0.jpg',
    ),
    'Scissors_Jump': ExerciseCoaching(
      howTo: [
        'Drop into a lunge with one foot forward, front knee bent over the midfoot and the rear knee near the ground.',
        'Explode straight up through both legs, scissoring your legs in the air to switch positions.',
        'Land softly in a lunge with the opposite foot forward.',
      ],
      formChecks: [
        'Drop into a deep lunge',
        'Keep front knee over the foot',
        'Explode up and switch legs',
        'Land soft in a lunge',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=peQW4IEMQ_U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Scissors_Jump/0.jpg',
    ),
    'Side_Hop-Sprint': ExerciseCoaching(
      howTo: [
        'Stand to one side of a cone or low hurdle with feet together.',
        'Hop sideways over it and rebound quickly off your landing to hop straight back.',
        'Keep the lateral hops fast and reactive, then finish the set by exploding into a short sprint.',
      ],
      formChecks: [
        'Hop side to side over it',
        'Rebound fast off each landing',
        'Explode into the sprint',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gOTcL6muJKk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Hop-Sprint/0.jpg',
    ),
    'Side_Standing_Long_Jump': ExerciseCoaching(
      howTo: [
        'Stand in an athletic stance with feet hip-width, chest up and knees slightly bent.',
        'Lean toward one side and extend explosively through your hips, knees, and ankles to jump laterally as far as you can.',
        'Land balanced on both feet with soft, bent knees.',
      ],
      formChecks: [
        'Push off the trailing leg',
        'Extend hips to jump sideways',
        'Stick a balanced landing',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5IgFWp9ETvU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_Standing_Long_Jump/0.jpg',
    ),
    'Side_to_Side_Box_Shuffle': ExerciseCoaching(
      howTo: [
        'Stand to one side of a box with your left foot resting on top of it.',
        'Jump up and across to the other side, switching feet so your right foot lands on the box and your left foot hits the floor.',
        'Swing your arms to drive the movement and keep shuffling side to side.',
      ],
      formChecks: [
        'Switch feet over the box',
        'Swing arms to drive across',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WMomlX3koWw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Side_to_Side_Box_Shuffle/0.jpg',
    ),
    'Single_Leg_Butt_Kick': ExerciseCoaching(
      howTo: [
        'Balance on one leg with the opposite knee lifted.',
        'Drop into a fast countermovement dip, then jump straight up by driving through hip, knee, and ankle.',
        'At the top, snap your grounded heel up toward your glute, then land soft on the same leg.',
      ],
      formChecks: [
        'Quick dip to load the leg',
        'Explode straight up',
        'Snap heel to glute at the top',
        'Land soft on the same leg',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eW6j8aLS3po',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Leg_Butt_Kick/0.jpg',
    ),
    'Single_Leg_Push-off': ExerciseCoaching(
      howTo: [
        'Set one foot flat on a low box with the heel near the edge and the other foot on the floor.',
        'Drive hard through the top foot, extending your hip and knee to spring up as high as you can.',
        'Land with the same foot back on the box and reset.',
      ],
      formChecks: [
        'Spring up off the box foot',
        'Land that foot back on the box',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Ygq5RwOJ-bw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single_Leg_Push-off/0.jpg',
    ),
    'Single-Cone_Sprint_Drill': ExerciseCoaching(
      howTo: [
        'Stand beside a single cone with one arm forward and one back.',
        'Chop your feet as fast as possible while pumping the arms to block.',
        'Keep the knees high and drive the action hard as you circle around the cone.',
      ],
      formChecks: [
        'Chop the feet as fast as you can',
        'Knees high, arms pumping',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KuWgqdURDUY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Cone_Sprint_Drill/0.jpg',
    ),
    'Single-Leg_Hop_Progression': ExerciseCoaching(
      howTo: [
        'Line up several low cones ahead of you and balance on one leg with the opposite knee raised.',
        'Hop forward over each cone, taking off and landing on the same leg.',
        'Use the arms to drive height as you move down the line.',
      ],
      formChecks: [
        'Take off and land same leg',
        'Clear each cone down the line',
        'Drive height with the arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IkkX3PTt180',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Hop_Progression/0.jpg',
    ),
    'Single-Leg_Lateral_Hop': ExerciseCoaching(
      howTo: [
        'Stand to one side of a low cone, balanced on one leg with the knee slightly bent.',
        'Counter-dip, then hop sideways over the cone off that same leg.',
        'Land on the jumping leg and immediately rebound back across.',
      ],
      formChecks: [
        'Hop sideways over the cone',
        'Land and rebound back fast',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=tQpacdoxSJg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Lateral_Hop/0.jpg',
    ),
    'Single-Leg_Stride_Jump': ExerciseCoaching(
      howTo: [
        'Stand beside a box with your inside foot on top near the edge.',
        'Swing both arms up and push hard through the top leg, jumping as high as you can while driving the opposite knee upward.',
        'Land softly and reset on the same side.',
      ],
      formChecks: [
        'Push hard through the top leg',
        'Swing both arms up for height',
        'Drive the opposite knee up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Nz7yP4DmAv0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_Stride_Jump/0.jpg',
    ),
    'Sledgehammer_Swings': ExerciseCoaching(
      howTo: [
        'Stand about two feet from a tire in a staggered stance, gripping a sledgehammer with your bottom hand at the base of the handle.',
        'Swing the hammer up overhead, then drive it down hard to strike the tire, rotating through your core.',
        'Slide the top hand down as you swing.',
      ],
      formChecks: [
        'Stagger your stance to the tire',
        'Slide top hand down as you swing',
        'Rotate through the core',
        'Strike the tire hard',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=et-D15fF5NU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sledgehammer_Swings/0.jpg',
    ),
    'Split_Jump': ExerciseCoaching(
      howTo: [
        'Drop into a lunge with the front knee bent over your foot and the rear knee nearly touching the floor.',
        'Extend explosively through both legs to jump as high as you can, swinging the arms up.',
        'Land softly back in the lunge and absorb through both legs.',
      ],
      formChecks: [
        'Drop into a deep lunge',
        'Front knee stacked over the foot',
        'Explode up through both legs',
        'Land back in the lunge',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LMkQHNtMsmA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Jump/0.jpg',
    ),
    'Standing_Long_Jump': ExerciseCoaching(
      howTo: [
        'Stand in a partial squat with feet shoulder width apart.',
        'Swing the arms back, then throw them forward as you extend the legs and jump out for maximum distance.',
        'Land in a soft squat on both feet with the knees bent.',
      ],
      formChecks: [
        'Throw the arms forward hard',
        'Jump out for max distance',
        'Land soft in a squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AO57oC3Cw14',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Long_Jump/0.jpg',
    ),
    'Standing_Two-Arm_Overhead_Throw': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder width apart holding a medicine ball in both hands.',
        'Reach it deep behind your head as you bend the knees and lean back.',
        'Throw the ball forward with force, flexing at the hips as the arms snap overhead and through.',
      ],
      formChecks: [
        'Load deep behind your head',
        'Snap the hips forward',
        'Release the ball overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SutFe2ijymU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Two-Arm_Overhead_Throw/0.jpg',
    ),
    'Star_Jump': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder width apart and arms held close to your body.',
        'Squat down halfway, then explode straight up as high as possible.',
        'Spread your arms and legs wide into a star at the peak, then pull them back in to land soft in a quarter squat.',
      ],
      formChecks: [
        'Explode up into a wide star',
        'Pull in to land soft',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=yGQZR6n7nfc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Star_Jump/0.jpg',
    ),
    'Stride_Jump_Crossover': ExerciseCoaching(
      howTo: [
        'Stand beside a box with your inside foot on top near the edge.',
        'Swing the arms up and push hard through the top leg to jump high, driving the opposite knee up and across the box.',
        'Land on the far side and reset with the other foot on top.',
      ],
      formChecks: [
        'Push hard through the top leg',
        'Drive the knee up and across',
        'Land on the far side',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hsHlBTj3_H8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stride_Jump_Crossover/0.jpg',
    ),
    'Supine_Chest_Throw': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees bent and hold a medicine ball on your chest, hands on the bottom of the ball.',
        'Explode it straight up by extending the arms fully, like a chest pass to the ceiling.',
        'Catch it on the way down and absorb back to your chest.',
      ],
      formChecks: [
        'Punch the ball to the ceiling',
        'Catch it back to your chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6pxEAMx_lPI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Supine_Chest_Throw/0.jpg',
    ),
    'Supine_One-Arm_Overhead_Throw': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees bent, holding a medicine ball in one hand with the arm extended fully behind your head.',
        'Initiate at the shoulder and throw the ball forward and up, crunching through your core.',
        'Reset the arm overhead and switch hands as needed.',
      ],
      formChecks: [
        'Start arm fully behind your head',
        'Drive from the shoulder',
        'Crunch up as you throw',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=GPmscIDo5gc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Supine_One-Arm_Overhead_Throw/0.jpg',
    ),
    'Supine_Two-Arm_Overhead_Throw': ExerciseCoaching(
      howTo: [
        'Lie on your back with knees bent, holding a medicine ball in both hands with the arms extended fully behind your head.',
        'Initiate at the shoulders and throw the ball forward and up, crunching hard through your core.',
        'Bring the arms back overhead to reset.',
      ],
      formChecks: [
        'Load both arms behind your head',
        'Crunch hard and throw up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=uPqAd82GUfY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Supine_Two-Arm_Overhead_Throw/0.jpg',
    ),
    'Vertical_Swing': ExerciseCoaching(
      howTo: [
        'Grip one dumbbell with both hands, arms hanging between your legs.',
        'Hinge at the hips with a slight knee bend and let the dumbbell swing back between your thighs.',
        'Snap the hips forward to power it up to chest height, then let it swing back down.',
      ],
      formChecks: [
        'Hinge at the hips, not the knees',
        'Snap the hips to drive it up',
        'Arms stay loose, guide only',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cfYt7Q21w_0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Vertical_Swing/0.jpg',
    ),
    'Weighted_Jump_Squat': ExerciseCoaching(
      howTo: [
        'Set a lightly loaded barbell across your upper back and stand with feet shoulder-width apart.',
        'Dip into a quarter squat, then explode up and jump off the floor.',
        'Land softly with bent knees to absorb the impact.',
      ],
      formChecks: [
        'Dip only a quarter squat',
        'Explode up off the floor',
        'Land soft with bent knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Dw_NTWcv8-8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Jump_Squat/0.jpg',
    ),
    'Backward_Drag': ExerciseCoaching(
      howTo: [
        'Load a sled and hold the rope or straps with arms extended.',
        'Lean back against the weight and walk backwards in short quick steps.',
        'Extend hard through the knees with each step to drag the sled as fast as you can.',
      ],
      formChecks: [
        'Lean back against the sled',
        'Quick steps, knees punching straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=k7JsvdG9sSo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Backward_Drag/0.jpg',
    ),
    'Barbell_Side_Split_Squat': ExerciseCoaching(
      howTo: [
        'Rest a barbell across your upper back and stand with feet wide, lead foot angled out to the side.',
        'Shift onto the lead leg, bending that knee and pushing your hips back while the trailing leg stays straight.',
        'Push through the bent leg to return to center.',
      ],
      formChecks: [
        'Angle the lead foot out',
        'Bend only the lead knee',
        'Keep the trailing leg straight',
        'Track the knee over the toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VnWGhQgFbSM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Side_Split_Squat/0.jpg',
    ),
    'Barbell_Squat': ExerciseCoaching(
      howTo: [
        'Set the bar just below shoulder height, step under it and rest it across your upper back.',
        'Drive through your legs to unrack, step back to a shoulder-width stance with toes slightly out.',
        'Sit the hips back and bend the knees until the hamstrings meet the calves, then drive up through the mid-foot to standing.',
      ],
      formChecks: [
        'Head up, back flat throughout',
        'Brace before you descend',
        'Inhale down, exhale up',
        'Push the floor away through heel and mid-foot',
        'Knees track over the toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rrJIyZGlK8c',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat/0.jpg',
    ),
    'Barbell_Squat_To_A_Bench': ExerciseCoaching(
      howTo: [
        'Set a flat bench or box behind you and unrack a barbell across your upper back.',
        'Stand just in front of the bench with feet shoulder-width.',
        'Push your hips back and squat down until you lightly touch the bench, then drive through your heels to stand.',
      ],
      formChecks: [
        'Push the hips back to the bench',
        'Touch light, don\'t crash down',
        'Drive up off the bench',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Dl-Ao8U9YxI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat_To_A_Bench/0.jpg',
    ),
    'Barbell_Step_Ups': ExerciseCoaching(
      howTo: [
        'Hold a barbell across your upper back and stand facing an elevated platform.',
        'Place one foot flat on the platform and drive through that heel to step up until the leg is straight.',
        'Lower back down under control, then switch legs.',
      ],
      formChecks: [
        'Drive through the top-foot heel',
        'Don\'t push off the bottom foot',
        'Stand tall at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hbIMKzHuglA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Step_Ups/0.jpg',
    ),
    'Bear_Crawl_Sled_Drags': ExerciseCoaching(
      howTo: [
        'Strap a harness around your waist with the sled chained behind you.',
        'Drop onto all fours with hands on the floor, back flat and knees bent just off the ground.',
        'Crawl forward moving opposite hand and foot together, driving through your legs to haul the sled.',
      ],
      formChecks: [
        'Keep the knees hovering low',
        'Move opposite hand and foot',
        'Drag forward with the legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QVr6nUzPuTM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bear_Crawl_Sled_Drags/0.jpg',
    ),
    'Bicycling': ExerciseCoaching(
      howTo: [
        'Set the saddle so your leg is almost straight at the bottom of the pedal stroke.',
        'Grip the handlebars and pedal, pushing down through the ball of each foot.',
        'Keep a steady cadence and pull through the bottom of the stroke to keep the quads working.',
      ],
      formChecks: [
        'Set the saddle for near-full extension',
        'Push through the balls of the feet',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gWosN1CY4bg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bicycling/0.jpg',
    ),
    'Bicycling_Stationary': ExerciseCoaching(
      howTo: [
        'Adjust the seat so your knee stays slightly bent at the bottom of each stroke.',
        'Select a manual setting or program and dial in the resistance.',
        'Pedal at a steady pace, driving down through each foot and keeping tension in the quads throughout.',
      ],
      formChecks: [
        'Slight knee bend at the bottom',
        'Dial in enough resistance',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NwwDBARCGgo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bicycling_Stationary/0.jpg',
    ),
    'Bodyweight_Squat': ExerciseCoaching(
      howTo: [
        'Stand with feet shoulder-width apart and hands behind your head or out in front.',
        'Bend your knees and push your hips back, keeping your chest up, and lower until your thighs are at least parallel.',
        'Drive through your heels to stand tall.',
      ],
      formChecks: [
        'Push the hips back and down',
        'Keep the chest up',
        'Sink to at least parallel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=l83R5PblSMA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Squat/0.jpg',
    ),
    'Box_Squat': ExerciseCoaching(
      howTo: [
        'Set a box at about parallel height behind you and unrack a barbell across your upper back.',
        'Stand with a slightly wide stance and push your hips back to sit down onto the box.',
        'Pause briefly, then drive up through your heels without bouncing off it.',
      ],
      formChecks: [
        'Sit the hips back onto the box',
        'Pause, don\'t bounce off',
        'Explode up off the box',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rMEPHwNhQfo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Squat/0.jpg',
    ),
    'Box_Squat_with_Chains': ExerciseCoaching(
      howTo: [
        'Drape chains over the barbell sleeves, unrack it across your upper back, and set a box behind you at parallel height.',
        'Sit your hips back onto the box as the chains pile on the floor.',
        'Pause, then drive up explosively as the chains reload the bar.',
      ],
      formChecks: [
        'Sit back onto the box',
        'Chains pile up at the bottom',
        'Pause without bouncing',
        'Accelerate up as chains reload',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9V6E0L69P20',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Box_Squat_with_Chains/0.jpg',
    ),
    'Calf_Press_On_The_Leg_Press_Machine': ExerciseCoaching(
      howTo: [
        'Sit in the leg press and place just the balls of your feet on the lower edge of the platform, heels off.',
        'Release the safety bars and straighten your legs.',
        'Press the platform away by extending your ankles and squeezing the calves, then let your toes come back.',
      ],
      formChecks: [
        'Balls of feet on the platform edge',
        'Full stretch down, press onto the toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=p5dCqF7wWUw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Calf_Press_On_The_Leg_Press_Machine/0.jpg',
    ),
    'Chair_Squat': ExerciseCoaching(
      howTo: [
        'Set the machine bar to your height and load it, then step under and position it across the back of your shoulders.',
        'Take the bar with your hands facing forward, unlock it, and lift it off the rack.',
        'Bend your knees and hips to squat to about parallel, then press through your heels to stand.',
      ],
      formChecks: [
        'Sit back like into a chair',
        'Push up through the heels',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gST_9kPV9q4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Chair_Squat/0.jpg',
    ),
    'Conans_Wheel': ExerciseCoaching(
      howTo: [
        'Load the implement and cradle its end in the crooks of your elbows, gripping your own wrists.',
        'Brace hard and lift it off the ground by extending your legs.',
        'Keep your chest tall and walk in a circle around the pivot for as long as you can.',
      ],
      formChecks: [
        'Cradle it in your elbow crooks',
        'Stand it up with your legs',
        'Keep the chest tall',
        'Short, fast steps around',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oEsyO1PVDNY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Conans_Wheel/0.jpg',
    ),
    'Elliptical_Trainer': ExerciseCoaching(
      howTo: [
        'Step onto the pedals and take hold of the moving handles.',
        'Push down and around through the balls of your feet, driving each pedal through a smooth oval stride.',
        'Keep an upright posture and let your legs power the motion.',
      ],
      formChecks: [
        'Drive the balls of your feet around the oval',
        'Stand tall, don\'t lean on the handles',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=d39RwvdQZEk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Elliptical_Trainer/0.jpg',
    ),
    'Frankenstein_Squat': ExerciseCoaching(
      howTo: [
        'Rest the barbell across the front of your shoulders and extend both arms straight out, releasing your grip.',
        'Keep the chest tall and the arms level.',
        'Bend the knees to squat down until the thighs pass parallel, then drive up through the heels.',
      ],
      formChecks: [
        'Extend arms straight, release the grip',
        'Balance the bar on your front delts',
        'Stay tall so the bar can\'t roll',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7XBD6CXCO6g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Frankenstein_Squat/0.jpg',
    ),
    'Front_Barbell_Squat': ExerciseCoaching(
      howTo: [
        'Rack the bar across the front of the shoulders with the elbows high, take a shoulder-width stance and brace.',
        'Sit straight down between the hips keeping the torso as upright as possible, then drive up through the mid-foot.',
      ],
      formChecks: [
        'Elbows up, chest tall, don\'t let them drop',
        'Keep the torso vertical',
        'Sit between the hips, knees tracking over the toes',
        'Brace hard before each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Q1Ypb8ZNzI4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Barbell_Squat/0.jpg',
    ),
    'Front_Barbell_Squat_To_A_Bench': ExerciseCoaching(
      howTo: [
        'Set a flat bench behind you and rack the bar across the front of your shoulders with elbows high.',
        'Squat straight down until your glutes lightly tap the bench, keeping the chest up.',
        'Drive through the heels to stand back up.',
      ],
      formChecks: [
        'Keep the elbows high and chest up',
        'Tap the bench, don\'t sit down',
        'Drive up through the heels',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=23eRDK_prHc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Barbell_Squat_To_A_Bench/0.jpg',
    ),
    'Front_Squat_Clean_Grip': ExerciseCoaching(
      howTo: [
        'Rack the bar on your front delts with a clean grip, fingers under the bar and elbows pointed high.',
        'Brace and descend by bending the knees until the thighs break parallel.',
        'Drive up through the heels, keeping the torso upright and elbows lifted.',
      ],
      formChecks: [
        'Fingertips under the bar',
        'Point the elbows high and forward',
        'Keep the torso vertical',
        'Break parallel with the knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FordZjG5K8s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Squat_Clean_Grip/0.jpg',
    ),
    'Front_Squats_With_Two_Kettlebells': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders and rest them in the front rack with elbows tucked in.',
        'Keep your eyes forward and chest tall.',
        'Bend the knees to squat down until the thighs reach parallel, then extend through the legs and hips to stand.',
      ],
      formChecks: [
        'Rack the bells on your shoulders',
        'Keep elbows tucked, wrists straight',
        'Squat to parallel, then stand',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=a7HZu0R9aPQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Front_Squats_With_Two_Kettlebells/0.jpg',
    ),
    'Goblet_Squat': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell or kettlebell vertically against the chest.',
        'Sit straight down between the hips until the elbows brush the inside of the knees, then stand back up tall.',
      ],
      formChecks: [
        'Chest up, weight tight to the body',
        'Sit between the hips, heels flat',
        'Elbows inside the knees at the bottom',
        'Brace the core throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xRTMjjZ76GI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Goblet_Squat/0.jpg',
    ),
    'Hack_Squat': ExerciseCoaching(
      howTo: [
        'Set your shoulders and back against the pad with feet shoulder-width on the platform.',
        'Lower under control until the thighs are at least parallel, then press up through the heels without locking the knees hard.',
      ],
      formChecks: [
        'Keep the whole back flat against the pad',
        'Knees track over the toes, don\'t cave in',
        'Control the descent',
        'Stop just short of locking the knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rYgNArpwE7E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hack_Squat/0.jpg',
    ),
    'Hip_Flexion_with_Band': ExerciseCoaching(
      howTo: [
        'Attach a band to a low post and secure the other end around one ankle, then face away from the anchor.',
        'Keeping your head and chest up, raise that knee up to about 90 degrees and hold briefly.',
        'Lower the leg under control back down.',
      ],
      formChecks: [
        'Drive the knee up to 90 degrees',
        'Stay tall on the standing leg',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=U7KaLsN3uE8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hip_Flexion_with_Band/0.jpg',
    ),
    'Jefferson_Squats': ExerciseCoaching(
      howTo: [
        'Straddle the barbell so it runs between your legs, then grip it with one hand in front and one behind, palms neutral.',
        'With a flat back and chest up, bend the knees to lower into a squat.',
        'Drive through the legs to stand tall, keeping the bar close.',
      ],
      formChecks: [
        'Straddle the bar between your legs',
        'One hand grips front, one behind',
        'Keep a flat back, chest tall',
        'Push up evenly through both legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IUux7YUcd54',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jefferson_Squats/0.jpg',
    ),
    'Jogging_Treadmill': ExerciseCoaching(
      howTo: [
        'Step onto the treadmill deck and set a comfortable jogging speed.',
        'Run with a tall posture, landing midfoot under your hips and driving the knees forward.',
        'Swing the arms in rhythm and hold a steady, controlled pace.',
      ],
      formChecks: [
        'Land midfoot under your hips',
        'Run tall with loose shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LsswRe8_I3g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jogging_Treadmill/0.jpg',
    ),
    'Kettlebell_Turkish_Get-Up_Squat_style': ExerciseCoaching(
      howTo: [
        'Lie on your back and press one kettlebell to a locked-out arm above your shoulder.',
        'Keeping the elbow locked and eyes on the bell, rise to your feet through a series of controlled steps.',
        'Stand fully, then reverse each step back to the floor.',
      ],
      formChecks: [
        'Press the bell to a locked arm',
        'Keep the elbow locked throughout',
        'Keep your eyes on the bell',
        'Rise and reverse one step at a time',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eez_eneSDsw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Turkish_Get-Up_Squat_style/0.jpg',
    ),
    'Kneeling_Squat': ExerciseCoaching(
      howTo: [
        'Rack a barbell across your upper back and kneel upright on a padded surface with knees hip-width.',
        'Sit your hips back toward your heels while keeping the torso tall.',
        'Squeeze the glutes and drive the hips forward to return upright.',
      ],
      formChecks: [
        'Sit the hips back to your heels',
        'Thrust the hips forward to rise',
        'Don\'t overarch the lower back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=k_Vo-cad1iM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kneeling_Squat/0.jpg',
    ),
    'Leg_Press': ExerciseCoaching(
      howTo: [
        'Sit with the back flat against the pad and feet shoulder-width on the platform.',
        'Lower until the knees reach about 90 degrees, then press through the heels without letting the hips curl off the seat.',
      ],
      formChecks: [
        'Don\'t let the lower back round off the pad',
        'Knees track over the toes',
        'Stop before the knees lock out',
        'Control the weight down, don\'t drop it',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=qCR9bN3G1t4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leg_Press/0.jpg',
    ),
    'Lying_Machine_Squat': ExerciseCoaching(
      howTo: [
        'Lie face up in the machine with your feet on the platform and knees bent so the thighs sit just below parallel.',
        'Press through the feet to extend the legs and push the platform away.',
        'Bend the knees to lower back down under control.',
      ],
      formChecks: [
        'Start with thighs below parallel',
        'Stop short of locking the knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fUu6vgi7djY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Lying_Machine_Squat/0.jpg',
    ),
    'Narrow_Stance_Hack_Squats': ExerciseCoaching(
      howTo: [
        'Set your back against the pad and hook your shoulders under the pads.',
        'Place your feet on the platform in a narrow, less-than-shoulder-width stance with toes turned slightly out.',
        'Bend the knees to lower down, then press through the feet to rise.',
      ],
      formChecks: [
        'Keep feet narrow, toes slightly out',
        'Press your back flat to the pad',
        'Let the knees track over the toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7sNgnNL-dTY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Narrow_Stance_Hack_Squats/0.jpg',
    ),
    'Narrow_Stance_Leg_Press': ExerciseCoaching(
      howTo: [
        'Sit in the leg press and place your feet on the platform close together, a few inches apart, with toes slightly out.',
        'Release the safeties and bend the knees to lower the platform toward your chest.',
        'Press through the feet to extend the legs.',
      ],
      formChecks: [
        'Set feet a few inches apart',
        'Stop before the knees lock',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6GT9o4Cp1vA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Narrow_Stance_Leg_Press/0.jpg',
    ),
    'Narrow_Stance_Squats': ExerciseCoaching(
      howTo: [
        'Rack the bar across your upper back and step out with a narrow, closer-than-shoulder-width stance.',
        'Brace your core and bend the knees to squat down until the thighs reach parallel.',
        'Drive up through the heels to stand tall.',
      ],
      formChecks: [
        'Set a narrow, close stance',
        'Brace and drop to parallel',
        'Push through the heels to stand',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1IIPcUCKxcE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Narrow_Stance_Squats/0.jpg',
    ),
    'Olympic_Squat': ExerciseCoaching(
      howTo: [
        'Support the bar high on your traps with chest up and a hip-width stance, toes turned slightly out.',
        'Bend the knees and let them travel forward as you drop into a deep squat, keeping the torso upright.',
        'Drive up through the whole foot to stand.',
      ],
      formChecks: [
        'Let the knees travel forward',
        'Keep the torso upright',
        'Squat deep with heels down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lrmYf-RSr6s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Olympic_Squat/0.jpg',
    ),
    'One_Leg_Barbell_Squat': ExerciseCoaching(
      howTo: [
        'Set a loaded barbell across your upper back and stand a couple feet in front of a bench, back facing it.',
        'Rest the top of one foot behind you on the bench.',
        'Lower by bending the front knee until the thigh is parallel, then drive through the front heel to stand.',
      ],
      formChecks: [
        'Rest rear foot on the bench',
        'Drop the back knee straight down',
        'Load the front leg, not the back',
        'Drive up through the front heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=j-D3ztzIHSc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Leg_Barbell_Squat/0.jpg',
    ),
    'One-Arm_Overhead_Kettlebell_Squats': ExerciseCoaching(
      howTo: [
        'Clean and press one kettlebell to a locked-out position overhead, arm by your ear.',
        'Set feet shoulder width with toes slightly out.',
        'Keeping the bell stacked over the shoulder, sit down into a squat until the thighs pass parallel, then stand tall.',
      ],
      formChecks: [
        'Stack the bell over the shoulder',
        'Lock the overhead elbow',
        'Squat below parallel',
        'Keep chest tall, eyes ahead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DTlcsr75WR0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Overhead_Kettlebell_Squats/0.jpg',
    ),
    'Overhead_Squat': ExerciseCoaching(
      howTo: [
        'Take a wide snatch grip and press the barbell to full lockout overhead, feet slightly wider than the shoulders.',
        'Push the bar back so it sits over your midfoot.',
        'Squat down as deep as mobility allows while keeping the bar overhead, then drive up.',
      ],
      formChecks: [
        'Wide snatch grip, elbows locked',
        'Keep the bar over midfoot',
        'Actively push the bar up',
        'Squat deep, bar stays back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oGV21KvorfM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Overhead_Squat/0.jpg',
    ),
    'Plie_Dumbbell_Squat': ExerciseCoaching(
      howTo: [
        'Hold a single dumbbell vertically by one end with both hands, arms hanging straight.',
        'Set your feet well outside shoulder width with the toes turned out.',
        'Lower straight down by bending the knees until the thighs are parallel, then squeeze up to standing.',
      ],
      formChecks: [
        'Set feet wide, toes turned out',
        'Lower straight down, torso tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3kinQm0KDvE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plie_Dumbbell_Squat/0.jpg',
    ),
    'Recumbent_Bike': ExerciseCoaching(
      howTo: [
        'Sit down on the recumbent bike and adjust the seat to your height.',
        'Select a program from the menu or use the manual setting, pedaling to power it on if needed.',
        'Then pedal at a steady, controlled cadence.',
      ],
      formChecks: [
        'Set seat for a slight knee bend',
        'Hold a smooth, steady cadence',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ckJRUKyJ8cI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Recumbent_Bike/0.jpg',
    ),
    'Reverse_Band_Box_Squat': ExerciseCoaching(
      howTo: [
        'Set bands from the top of the rack down to the bar so they pull upward, and place a box behind you.',
        'Unrack with the bar on your upper back and stand over the box.',
        'Sit back and down until you settle on the box, then drive up as the bands assist off the bottom.',
      ],
      formChecks: [
        'Sit back onto the box',
        'Stay tight while seated',
        'Explode up as the bands lighten',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5QknhGWyw_g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Box_Squat/0.jpg',
    ),
    'Reverse_Band_Power_Squat': ExerciseCoaching(
      howTo: [
        'Attach bands from the top of the rack to each end of the bar so they pull up.',
        'Unrack with the bar on your upper back and set a wide stance.',
        'Sit back and squat below parallel, then drive up powerfully as the bands lighten the load at the bottom.',
      ],
      formChecks: [
        'Take a wide stance',
        'Break at the hips first',
        'Drive hard out of the hole',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jThQQAC6WmY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Reverse_Band_Power_Squat/0.jpg',
    ),
    'Running_Treadmill': ExerciseCoaching(
      howTo: [
        'Step onto the treadmill deck and select a program or manual speed from the menu.',
        'Start the belt slow and build up to your running pace.',
        'Run with a tall posture and quick foot turnover, landing under your hips.',
      ],
      formChecks: [
        'Land with feet under your hips',
        'Stay tall, quick light steps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aM0klz2hi4w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Running_Treadmill/0.jpg',
    ),
    'Sandbag_Load': ExerciseCoaching(
      howTo: [
        'Straddle the sandbag and squat down, wrapping both arms fully underneath it.',
        'Brace hard and stand by driving through the legs, hugging the bag to your chest.',
        'Carry it to the platform and heave it up onto the ledge, then reset for the next lift.',
      ],
      formChecks: [
        'Wrap both arms under the bag',
        'Hug it high on your chest',
        'Stand and heave with the legs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ktZVxyZ5XoQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sandbag_Load/0.jpg',
    ),
    'Single-Leg_High_Box_Squat': ExerciseCoaching(
      howTo: [
        'Set a high box in a rack with a band or rope hanging above for balance.',
        'Plant one foot flat on the box and hold the band lightly.',
        'Drive through that heel to step up to a full stand on one leg, then lower under control back down.',
      ],
      formChecks: [
        'Plant the foot flat on the box',
        'Drive up through the top heel',
        'Use the band for balance only',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NnJk2SDaRY4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Leg_High_Box_Squat/0.jpg',
    ),
    'Skating': ExerciseCoaching(
      howTo: [
        'Stand with skates hip width and knees soft, weight centered over the wheels.',
        'Push one leg out to the side and back to drive yourself forward, then glide on the other.',
        'Alternate legs in a steady rhythm, keeping the knees bent to absorb and power each stride.',
      ],
      formChecks: [
        'Push each leg out to the side',
        'Keep knees bent, weight centered',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Z8BkIZgJ5C0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Skating/0.jpg',
    ),
    'Sled_Drag_-_Harness': ExerciseCoaching(
      howTo: [
        'Load the sled and buckle the harness around your hips.',
        'Lean your body into the direction of travel until the strap pulls tight.',
        'Drive forward with short, powerful steps, extending each leg fully and pushing hard through the ground to keep the sled moving.',
      ],
      formChecks: [
        'Lean into the strap',
        'Short steps, extend each leg fully',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hWZmIvUEIyI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Drag_-_Harness/0.jpg',
    ),
    'Sled_Push': ExerciseCoaching(
      howTo: [
        'Load the sled and grip the handles with your arms fully extended.',
        'Set an athletic stance with a forward body lean and a flat back.',
        'Drive the sled forward by powering through the balls of your feet, fully extending the hips and knees with every stride.',
      ],
      formChecks: [
        'Arms long, back flat',
        'Push through the balls of the feet',
        'Fully extend hips and knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QwscR2BhdEg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Push/0.jpg',
    ),
    'Smith_Single-Leg_Split_Squat': ExerciseCoaching(
      howTo: [
        'Set a bench a couple feet behind the Smith machine and position the bar across your upper back.',
        'Rest the top of your rear foot on the bench and stand tall on the front leg.',
        'Lower until the front thigh is parallel, then press through the front heel to rise.',
      ],
      formChecks: [
        'Rear foot up on the bench',
        'Keep the front shin vertical',
        'Push through the front foot',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fZ5A97p_mGg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Single-Leg_Split_Squat/0.jpg',
    ),
    'Speed_Box_Squat': ExerciseCoaching(
      howTo: [
        'Anchor bands from the floor to each end of the loaded bar and set a box behind you at about parallel height.',
        'Unrack with the bar on your back and stand over the box.',
        'Sit back under control until you touch the box, then explode up as fast as possible.',
      ],
      formChecks: [
        'Sit back, don\'t crash onto the box',
        'Pause briefly on the box',
        'Explode up as fast as you can',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NQYo0ntlluU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Speed_Box_Squat/0.jpg',
    ),
    'Speed_Squats': ExerciseCoaching(
      howTo: [
        'Set the bar across your upper back in a squat rack and step out with feet shoulder-width, toes slightly out.',
        'Lower under control to about parallel, then drive up as explosively as you can.',
        'Keep every rep fast and crisp.',
      ],
      formChecks: [
        'Explode up out of the bottom',
        'Hit parallel, no deeper',
        'Keep every rep fast and crisp',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sz600ro-lj0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Speed_Squats/0.jpg',
    ),
    'Split_Squat_with_Dumbbells': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell in each hand and set up in a staggered stance with the top of your rear foot resting on a bench behind you.',
        'Descend by bending your front knee and hip until your rear knee nears the floor, then drive up through your front heel to stand.',
      ],
      formChecks: [
        'Rear foot resting on the bench',
        'Drive up through the front heel',
        'Sink your rear knee toward the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Fmjj7wFJWRE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Squat_with_Dumbbells/0.jpg',
    ),
    'Squat_with_Chains': ExerciseCoaching(
      howTo: [
        'Drape a chain over each sleeve of the bar so a few links rest on the floor at the top.',
        'Unrack with the bar on your upper back and set your feet shoulder-width.',
        'Lower until thighs reach parallel as the chains pile on the floor, then drive up as they lift and load.',
      ],
      formChecks: [
        'Let the chains pile at the bottom',
        'Drive up hard as the chains reload',
        'Feet shoulder-width, hit parallel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HNJgF6dOBbc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squat_with_Chains/0.jpg',
    ),
    'Squat_with_Plate_Movers': ExerciseCoaching(
      howTo: [
        'Set the bar just below shoulder height and place a weight plate on the floor a couple of feet behind the rack.',
        'Unrack the bar onto your upper back and step back over the plate, feet shoulder-width.',
        'Squat down until your thighs reach parallel, then drive through your heels to stand tall.',
      ],
      formChecks: [
        'Step back clear of the plate',
        'Sit down to full depth',
        'Drive up through your heels',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fg6p-vjlQog',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squat_with_Plate_Movers/0.jpg',
    ),
    'Squats_-_With_Bands': ExerciseCoaching(
      howTo: [
        'Stand on the middle of the band with feet shoulder-width, then pull the ends up to rest on top of your shoulders.',
        'Squat down until your thighs reach parallel against the band tension.',
        'Drive back up to standing as the band pulls harder near the top.',
      ],
      formChecks: [
        'Stand on the band\'s center',
        'Push hardest near the top',
        'Keep knees tracking over toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_xQOupXuDYY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squats_-_With_Bands/0.jpg',
    ),
    'Stairmaster': ExerciseCoaching(
      howTo: [
        'Step onto the stairmaster and select a manual setting or program, then start at an easy pace.',
        'Climb by driving down through each pedal with your whole foot.',
        'Stand tall, keep a light grip on the rails, and hold a steady rhythm.',
      ],
      formChecks: [
        'Stand tall, off the rails',
        'Press through your whole foot',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=V2EQYdMw4Do',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Stairmaster/0.jpg',
    ),
    'Step_Mill': ExerciseCoaching(
      howTo: [
        'Step onto the stepmill and pick a manual setting or program at a comfortable pace.',
        'Climb the revolving staircase by planting each foot fully and pushing through your heel.',
        'Keep your posture upright and let go of the rails as your balance allows.',
      ],
      formChecks: [
        'Plant each foot fully on the step',
        'Push through your heels',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=p6GTBhjQjeM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Step_Mill/0.jpg',
    ),
    'Suspended_Split_Squat': ExerciseCoaching(
      howTo: [
        'Set the strap handles 18 to 30 inches off the floor and face away from the anchor.',
        'Place the top of your rear foot in the handle and hop the front foot forward.',
        'Lower by bending your front knee until your rear knee nears the floor, then drive up through the front heel.',
      ],
      formChecks: [
        'Rear foot laced in the strap',
        'Drive up through the front heel',
        'Steady the swinging strap',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MPSGQuCz9Lo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Split_Squat/0.jpg',
    ),
    'Tire_Flip': ExerciseCoaching(
      howTo: [
        'Squat down to the tire with your chest driving into it and grip under the tread.',
        'Extend through your hips, knees, and ankles to drive the tire up, stepping into it as it rises.',
        'Once it tips past vertical, push it over to the ground.',
      ],
      formChecks: [
        'Chest driving into the tire',
        'Grip low under the tread',
        'Explode through your hips',
        'Step in and push it over',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ebWVMxbTK2k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Tire_Flip/0.jpg',
    ),
    'Trail_Running_Walking': ExerciseCoaching(
      howTo: [
        'Head out on a trail in supportive shoes and start at an easy pace to warm up.',
        'Drive up inclines by pushing hard through your legs, and shorten your stride on descents to control each step.',
        'Keep your eyes ahead to pick a clean line over roots and rocks.',
      ],
      formChecks: [
        'Shorten your stride downhill',
        'Drive hard up the climbs',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=SdIfc3FL6kU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Trail_Running_Walking/0.jpg',
    ),
    'Walking_Treadmill': ExerciseCoaching(
      howTo: [
        'Step onto the treadmill and select a manual setting or program, then start the belt at a walking pace.',
        'Walk with a natural heel-to-toe stride and stand tall through your torso.',
        'Raise the incline to load your legs more as you settle into a steady rhythm.',
      ],
      formChecks: [
        'Walk a natural heel-to-toe stride',
        'Raise the incline to load your quads',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9ccVxEvWtpA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Walking_Treadmill/0.jpg',
    ),
    'Weighted_Sissy_Squat': ExerciseCoaching(
      howTo: [
        'Grip a squat rack upright with one hand and hold a weight plate against your chest with the other, feet shoulder-width and up on your toes.',
        'Lower by driving your knees forward and leaning your torso back in a straight line.',
        'Pull with your quads to rise back up.',
      ],
      formChecks: [
        'Drive your knees forward',
        'Keep your body in a straight line',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LtVS8syZsTM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Sissy_Squat/0.jpg',
    ),
    'Wide_Stance_Barbell_Squat': ExerciseCoaching(
      howTo: [
        'Set the bar across your upper back in a squat rack and unrack it.',
        'Step your feet wider than shoulder-width with your toes turned out.',
        'Lower by sitting your hips down and back until your thighs reach parallel, then drive through your heels to stand tall.',
      ],
      formChecks: [
        'Feet wide, toes turned out',
        'Sit your hips down and back',
        'Track knees over your toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JXdGBp_YYz0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide_Stance_Barbell_Squat/0.jpg',
    ),
    'Zercher_Squats': ExerciseCoaching(
      howTo: [
        'Set the bar on a rack between waist and chest height and hook it into the crooks of your elbows.',
        'Stand it up with the bar held tight to your torso and feet shoulder-width.',
        'Squat down until your thighs pass parallel, then drive through your heels to stand.',
      ],
      formChecks: [
        'Bar hooked in your elbow crooks',
        'Keep elbows and chest lifted',
        'Stay upright as you squat down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nwx6Ip7hd3I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Zercher_Squats/0.jpg',
    ),
    'Close-Grip_Front_Lat_Pulldown': ExerciseCoaching(
      howTo: [
        'Sit with the thighs under the pads and take a close grip.',
        'Lean back slightly, chest up, and pull the handle to the upper chest by driving the elbows down and back, then return to a full stretch.',
      ],
      formChecks: [
        'Pull with the elbows, not the hands',
        'Bring the bar to the upper chest',
        'Squeeze the lats at the bottom',
        'Control the stretch, don\'t let it yank you up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IjoFCmLX7z0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Close-Grip_Front_Lat_Pulldown/0.jpg',
    ),
    'Full_Range-Of-Motion_Lat_Pulldown': ExerciseCoaching(
      howTo: [
        'Attach a stirrup handle to each high pulley and grab them with arms crossed, palms facing forward.',
        'Let the cables pull your arms fully overhead for a deep lat stretch.',
        'Pull your elbows down and out to your sides until your hands reach your shoulders, then rise under control.',
      ],
      formChecks: [
        'Cross the handles overhead',
        'Let your arms stretch fully up top',
        'Pull elbows down and out',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cczFstlkvzQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Full_Range-Of-Motion_Lat_Pulldown/0.jpg',
    ),
    'One_Arm_Lat_Pulldown': ExerciseCoaching(
      howTo: [
        'Attach a single handle to a high pulley and sit with the knee pad snug against your thighs.',
        'Grip the handle with your palm facing forward and arm extended overhead.',
        'Pull it down, driving your elbow to your side, then control it back up.',
      ],
      formChecks: [
        'Drive your elbow down to your ribs',
        'Reach tall for a full stretch',
        'Keep shoulders level, no twist',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XbZgoSNJXm4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Lat_Pulldown/0.jpg',
    ),
    'Rope_Straight-Arm_Pulldown': ExerciseCoaching(
      howTo: [
        'Attach a rope to a high pulley and stand a couple feet back with a staggered stance.',
        'Hinge forward from the hips with a straight back and take the rope with arms extended overhead.',
        'Sweep your arms down to your thighs, then control back up.',
      ],
      formChecks: [
        'Spread the rope at your thighs',
        'Arms straight, drive from the lats',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=G9uNaXGTJ4w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Rope_Straight-Arm_Pulldown/0.jpg',
    ),
    'Straight-Arm_Pulldown': ExerciseCoaching(
      howTo: [
        'Grab a wide bar on a high pulley with an overhand grip wider than shoulder width and step back about two feet.',
        'Hinge your torso forward about 30 degrees with arms extended toward the pulley.',
        'Sweep the bar down to your thighs in an arc, then return under control.',
      ],
      formChecks: [
        'Sweep the bar down in an arc',
        'Move only at the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=G9uNaXGTJ4w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Straight-Arm_Pulldown/0.jpg',
    ),
    'Underhand_Cable_Pulldowns': ExerciseCoaching(
      howTo: [
        'Sit at a pulldown station and lock your thighs under the knee pads.',
        'Take the bar with a shoulder-width underhand grip and extend your arms overhead.',
        'Pull the bar to your upper chest, driving your elbows down and back, then rise back to full stretch.',
      ],
      formChecks: [
        'Underhand grip, elbows driving down',
        'Pull the bar to your upper chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ENeMdS7iEjM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Underhand_Cable_Pulldowns/0.jpg',
    ),
    'V-Bar_Pulldown': ExerciseCoaching(
      howTo: [
        'With the thighs anchored and a neutral V-bar grip, lean back slightly and pull the bar to the upper chest, driving the elbows down.',
        'Return under control to a full stretch.',
      ],
      formChecks: [
        'Neutral grip, elbows drive down and in',
        'Chest up, slight lean back',
        'Squeeze the lats at the bottom',
        'Full stretch at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jmZMBYr0nHA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/V-Bar_Pulldown/0.jpg',
    ),
    'Wide-Grip_Lat_Pulldown': ExerciseCoaching(
      howTo: [
        'Sit at the pulldown machine and secure your thighs under the pads.',
        'Grab the wide bar with an overhand grip well outside shoulder width.',
        'Pull the bar down to your upper chest while driving your elbows down, then control it back to a full overhead stretch.',
      ],
      formChecks: [
        'Grip well outside your shoulders',
        'Chest up, slight lean back',
        'Pull to your chest, not behind',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lueEJGjTuPQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Lat_Pulldown/0.jpg',
    ),
    'Wide-Grip_Pulldown_Behind_The_Neck': ExerciseCoaching(
      howTo: [
        'Sit at the pulldown machine with your thighs under the pads and take the wide bar with a broad overhand grip.',
        'Keep your torso upright and head tilted slightly forward.',
        'Pull the bar down behind your head to the base of your neck, then return to a full stretch.',
      ],
      formChecks: [
        'Sit tall, chin slightly tucked',
        'Lower only as mobility allows',
        'To the base of the neck, no jerk',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=prmYGzw1Tds',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Wide-Grip_Pulldown_Behind_The_Neck/0.jpg',
    ),
    'Alternating_Kettlebell_Press': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders in the rack position with palms facing in.',
        'Press one kettlebell straight overhead to a full lockout.',
        'Lower it back to your shoulder, then press the other side, alternating each rep.',
      ],
      formChecks: [
        'Keep the resting bell racked tight',
        'Press one bell to full lockout',
        'Stay stacked, don\'t lean back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=AgujWwLc1OQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Alternating_Kettlebell_Press/0.jpg',
    ),
    'Anti-Gravity_Press': ExerciseCoaching(
      howTo: [
        'Set a barbell on the floor behind an incline bench and lie face down on the pad.',
        'Take an overhand grip and reverse curl the bar up to your chest.',
        'Press the bar forward and up until your arms lock out, then lower it back to your chest under control.',
      ],
      formChecks: [
        'Stay chest-down flat on the pad',
        'Reverse curl the bar to your chest',
        'Press forward and up to lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HXbetYIM-AY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Anti-Gravity_Press/0.jpg',
    ),
    'Arnold_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'Start with the dumbbells in front of the shoulders, palms facing you.',
        'Press overhead while rotating the palms to face forward, then reverse the rotation on the way down.',
      ],
      formChecks: [
        'Rotate smoothly through the press',
        'Keep the core braced',
        'Don\'t flare or bounce at the bottom',
        'Control the full range',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pQDrcNoDNVM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Arnold_Dumbbell_Press/0.jpg',
    ),
    'Bradford_Rocky_Presses': ExerciseCoaching(
      howTo: [
        'Sit on a press bench and hold the barbell at front shoulder level with an overhand grip just wider than your shoulders.',
        'Press up just high enough to clear your head, then lower the bar behind your neck.',
        'Press up again and return it to the front to complete one rep.',
      ],
      formChecks: [
        'Press just high enough to clear your head',
        'Alternate front and behind the neck',
        'Stay light, no lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=91tM_MYYNYM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bradford_Rocky_Presses/0.jpg',
    ),
    'Cuban_Press': ExerciseCoaching(
      howTo: [
        'Stand holding a dumbbell in each hand.',
        'Pull your elbows up until your upper arms are parallel to the floor with the dumbbells hanging down.',
        'Rotate your forearms up until they point overhead, press to lockout, then reverse the sequence back down.',
      ],
      formChecks: [
        'High pull elbows to shoulder height',
        'Rotate forearms up, elbows stay high',
        'Then press to lockout',
        'Go light to spare the cuff',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XpcOM9Np9LQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Cuban_Press/0.jpg',
    ),
    'Double_Kettlebell_Jerk': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders in the rack position.',
        'Dip at the knees, then explosively drive through your legs to launch the bells upward.',
        'Drop under and punch your arms to lockout overhead, stand tall, then lower back to the rack.',
      ],
      formChecks: [
        'Dip and drive hard through the legs',
        'Drop and punch under the bells',
        'Catch with arms stacked and locked',
        'Stand tall, then lower to the rack',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=eJlM35HAGmI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Jerk/0.jpg',
    ),
    'Double_Kettlebell_Push_Press': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders in the rack position.',
        'Dip a few inches at the knees, then rapidly reverse and drive through your legs.',
        'Use that momentum to press both bells overhead to a full lockout, then lower them back to your shoulders.',
      ],
      formChecks: [
        'Dip just a few inches',
        'Drive with the legs, then press',
        'Lock both bells out overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=nCNmFdiuqBc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Double_Kettlebell_Push_Press/0.jpg',
    ),
    'Dumbbell_One-Arm_Shoulder_Press': ExerciseCoaching(
      howTo: [
        'Sit on a bench with back support and clean one dumbbell to shoulder height with your palm facing forward.',
        'Brace your core, then press the dumbbell straight overhead until your arm locks out.',
        'Lower it back to your shoulder under control.',
      ],
      formChecks: [
        'Press straight up to lockout',
        'Don\'t lean away from the bell',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ZZTV-8yFXSg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_One-Arm_Shoulder_Press/0.jpg',
    ),
    'Dumbbell_Shoulder_Press': ExerciseCoaching(
      howTo: [
        'Seated or standing, start with the dumbbells at shoulder height, palms forward.',
        'Press overhead until the arms extend, then lower under control to the shoulders.',
      ],
      formChecks: [
        'Brace the core, don\'t arch the lower back',
        'Press slightly in, not straight out',
        'Full lockout overhead',
        'Control the weight back to the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0JfYxMRsUCQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Dumbbell_Shoulder_Press/0.jpg',
    ),
    'Jerk_Balance': ExerciseCoaching(
      howTo: [
        'Rack the barbell on your shoulders in the jerk position with your torso upright and feet split short.',
        'Dip straight down at the knees, then drive the bar up while pushing yourself down under it.',
        'Receive the bar overhead with locked arms in a split stance, then stand.',
      ],
      formChecks: [
        'Dip straight down, stay upright',
        'Drive under the bar fast',
        'Don\'t press it out with your arms',
        'Lock arms before you stand',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HpSYSPMEq9w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Jerk_Balance/0.jpg',
    ),
    'Kettlebell_Seesaw_Press': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders in the rack position.',
        'Press one bell overhead to lockout.',
        'As you lower it back down, begin pressing the other so the bells pass in a seesaw motion, alternating sides each rep.',
      ],
      formChecks: [
        'Pass the bells in a smooth seesaw',
        'Keep the low bell racked tight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0oJSOjmZN5I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kettlebell_Seesaw_Press/0.jpg',
    ),
    'Leverage_Shoulder_Press': ExerciseCoaching(
      howTo: [
        'Set the seat so the handles rest near the top of your shoulders and load the pins.',
        'Grip with palms forward, chest and head up.',
        'Press the handles overhead until your arms lock out, then lower under control to the start.',
      ],
      formChecks: [
        'Set seat so handles reach shoulders',
        'Press straight to overhead lockout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Jh_wCpZcTcY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Leverage_Shoulder_Press/0.jpg',
    ),
    'Machine_Shoulder_Military_Press': ExerciseCoaching(
      howTo: [
        'Sit tall, select the weight, and grab the handles at shoulder height with elbows bent in line with your torso.',
        'Press the handles up and exhale as your arms extend overhead.',
        'Lower slowly until your elbows return to the start.',
      ],
      formChecks: [
        'Start elbows in line with torso',
        'Exhale as arms extend up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=GcY6TZxfS0k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Machine_Shoulder_Military_Press/0.jpg',
    ),
    'One-Arm_Kettlebell_Jerk': ExerciseCoaching(
      howTo: [
        'Clean a kettlebell to your shoulder with your palm facing forward.',
        'Dip slightly at the knees, then drive explosively through the legs to launch the bell overhead.',
        'Drop under and lock the arm out, then stand tall and lower to the shoulder.',
      ],
      formChecks: [
        'Dip then explosive leg drive',
        'Drop under to catch lockout',
        'Stack wrist over elbow',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lmhvF6tr_cU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Jerk/0.jpg',
    ),
    'One-Arm_Kettlebell_Military_Press_To_The_Side': ExerciseCoaching(
      howTo: [
        'Clean a kettlebell to your shoulder with your palm facing inward.',
        'Keep your legs still and press the bell strictly overhead, letting the arm track out to the side.',
        'Lock out at the top, then lower under control to your shoulder.',
      ],
      formChecks: [
        'Palm faces inward',
        'Press strict, no leg drive',
        'Let the arm track to the side',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QQBZuMOqgEw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Military_Press_To_The_Side/0.jpg',
    ),
    'One-Arm_Kettlebell_Para_Press': ExerciseCoaching(
      howTo: [
        'Clean a kettlebell to your shoulder with your palm facing forward.',
        'Brace hard and press the bell straight overhead with no help from the legs.',
        'Lock the arm out at the top, then lower under control to your shoulder.',
      ],
      formChecks: [
        'Palm faces forward',
        'Press straight up, no leg drive',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=fFxC-C-wOrI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Para_Press/0.jpg',
    ),
    'One-Arm_Kettlebell_Push_Press': ExerciseCoaching(
      howTo: [
        'Clean a kettlebell to your shoulder with your palm facing forward.',
        'Dip slightly at the knees, then drive through the legs to help press the bell overhead.',
        'Lock out at the top, then lower under control to the shoulder.',
      ],
      formChecks: [
        'Dip then drive through legs',
        'Legs start, arm finishes',
        'No second dip up top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JbZrrnC5dvU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Push_Press/0.jpg',
    ),
    'One-Arm_Kettlebell_Split_Jerk': ExerciseCoaching(
      howTo: [
        'Clean a kettlebell to your shoulder with your palm forward.',
        'Dip at the knees and drive hard through the legs, then split your feet front and back as you punch the bell to lockout.',
        'Recover your feet together and lower to the shoulder.',
      ],
      formChecks: [
        'Dip and drive hard through legs',
        'Split feet front and back',
        'Punch arm under to lockout',
        'Recover feet together after',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=xoC_aBsawHM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One-Arm_Kettlebell_Split_Jerk/0.jpg',
    ),
    'Power_Jerk': ExerciseCoaching(
      howTo: [
        'Start with the barbell racked across your front shoulders and feet under your hips.',
        'Dip straight down at the knees, then drive explosively to launch the bar up.',
        'Drop under into a partial squat with arms locked overhead, then stand tall.',
      ],
      formChecks: [
        'Dip straight down, not back',
        'Drive explosively to launch bar',
        'Drop under into a partial squat',
        'Stand tall with arms locked',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MxTRnjBddrs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Power_Jerk/0.jpg',
    ),
    'Push_Press': ExerciseCoaching(
      howTo: [
        'Hold the bar on the front of the shoulders with a shoulder-width grip and elbows up.',
        'Dip briefly at the knees, then drive explosively through the legs to launch the bar overhead and lock the arms out.',
        'Lower under control to the shoulders and reset.',
      ],
      formChecks: [
        'Short, vertical dip, do not lean forward',
        'Drive with the legs, not just the arms',
        'Finish with the bar stacked over the mid-foot',
        'Brace the core throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=HKx22sWywxc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Push_Press/0.jpg',
    ),
    'Push_Press_-_Behind_the_Neck': ExerciseCoaching(
      howTo: [
        'Rack the barbell across your upper back behind your neck with feet under your hips.',
        'Dip straight down at the knees, then drive through the legs to press the bar overhead.',
        'Lock out over your head, then lower to the back of the shoulders.',
      ],
      formChecks: [
        'Rack the bar behind your neck',
        'Dip then drive through legs',
        'Bar finishes over the head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4hColgbAjSM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Push_Press_-_Behind_the_Neck/0.jpg',
    ),
    'Seated_Barbell_Military_Press': ExerciseCoaching(
      howTo: [
        'Sit on a press bench and take a barbell at shoulder height with a overhand grip just wider than your shoulders.',
        'Keep your torso upright and press the bar straight overhead until your arms lock out.',
        'Lower it under control to the front of your shoulders.',
      ],
      formChecks: [
        'Grip just outside shoulders',
        'No layback, stay upright',
        'Finish bar over mid-head',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4HCgc4S0z9g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Barbell_Military_Press/0.jpg',
    ),
    'Seated_Cable_Shoulder_Press': ExerciseCoaching(
      howTo: [
        'Sit at the cable station and grasp a handle in each hand at shoulder height, elbows bent about ninety degrees.',
        'With chest and head up, press the handles overhead until your arms extend.',
        'Lower under control until your elbows return to shoulder level.',
      ],
      formChecks: [
        'Start elbows bent near 90',
        'Press to full extension',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KrMEffEWnok',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Cable_Shoulder_Press/0.jpg',
    ),
    'Seated_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'Sit on a bench with back support and bring a dumbbell to each shoulder, palms facing forward.',
        'Press both dumbbells overhead until your arms extend and the weights nearly meet.',
        'Lower them under control back to shoulder height.',
      ],
      formChecks: [
        'Press until dumbbells nearly meet',
        'Keep your back on the pad',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1WOecdL8nrI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Seated_Dumbbell_Press/0.jpg',
    ),
    'See-Saw_Press_Alternating_Side_Press': ExerciseCoaching(
      howTo: [
        'Stand tall with a dumbbell at each shoulder, palms facing you.',
        'Press one dumbbell overhead while keeping the other at your shoulder.',
        'As you lower it, press the opposite arm up, alternating side to side in a see-saw rhythm.',
      ],
      formChecks: [
        'Press one up as the other lowers',
        'Tall torso, no side lean',
        'Alternate in a steady rhythm',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_LvchLGxNoY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/See-Saw_Press_Alternating_Side_Press/0.jpg',
    ),
    'Sled_Overhead_Backward_Walk': ExerciseCoaching(
      howTo: [
        'Attach two handles to a lightly loaded sled and face it.',
        'Raise both hands straight overhead with your elbows locked and back up until the line is tight.',
        'Keeping your arms fixed overhead, walk backward to drag the sled toward you.',
      ],
      formChecks: [
        'Lock arms straight overhead',
        'Keep the sled line tight',
        'Walk backward to drag it',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=XPFR58rk6s4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Sled_Overhead_Backward_Walk/0.jpg',
    ),
    'Smith_Machine_Overhead_Shoulder_Press': ExerciseCoaching(
      howTo: [
        'Set a bench with back support under the Smith bar and sit so the bar sits just above your shoulders.',
        'Unrack it with a overhand grip and press the bar straight up until your arms extend.',
        'Lower under control to the top of your chest.',
      ],
      formChecks: [
        'Follow the fixed bar path up',
        'Lower the bar to upper chest',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=b5v5za6q-xY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Smith_Machine_Overhead_Shoulder_Press/0.jpg',
    ),
    'Split_Jerk': ExerciseCoaching(
      howTo: [
        'Rack the bar across your front delts, feet under your hips.',
        'Dip straight down by bending the knees, then drive up explosively and punch the bar overhead.',
        'As it rises, split one foot forward and one back into a lunge and lock the arms, then recover the feet to standing.',
      ],
      formChecks: [
        'Dip straight down, torso tall',
        'Drive through legs, not arms',
        'Split feet front and back',
        'Catch with arms locked out',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=14j8oyHga9Y',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Split_Jerk/0.jpg',
    ),
    'Squat_Jerk': ExerciseCoaching(
      howTo: [
        'Rack the bar across your front delts, feet under your hips.',
        'Dip straight down by bending the knees, then drive up explosively and punch the bar overhead.',
        'Drop into a full squat to receive the bar locked out, then stand tall.',
      ],
      formChecks: [
        'Dip straight down, torso tall',
        'Drive up, then drop fast',
        'Catch locked out in a deep squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=p88wsnJfRz8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Squat_Jerk/0.jpg',
    ),
    'Standing_Alternating_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'Stand with a dumbbell at each shoulder, palms facing forward and elbows out.',
        'Brace your core and press one dumbbell straight overhead until the arm locks.',
        'Lower it under control to your shoulder, then press the other side.',
      ],
      formChecks: [
        'Press one dumbbell at a time',
        'Stay tall, don\'t lean away',
        'Hold the other bell at your shoulder',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=H2hC2M7SCYg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Alternating_Dumbbell_Press/0.jpg',
    ),
    'Standing_Barbell_Press_Behind_Neck': ExerciseCoaching(
      howTo: [
        'Set the bar in a rack at shoulder height and take a wide overhand grip.',
        'Step under and rest it across your upper traps behind your neck.',
        'Press it straight overhead until the arms lock, then lower it back behind the neck under control.',
      ],
      formChecks: [
        'Take a wide overhand grip',
        'Press straight up behind your head',
        'Lower to your traps, chest tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kMID_jRfV0I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Barbell_Press_Behind_Neck/0.jpg',
    ),
    'Standing_Bradford_Press': ExerciseCoaching(
      howTo: [
        'Rack the bar across your front shoulders with a shoulder-width overhand grip.',
        'Press it up just high enough to clear your head, then lower it behind your neck.',
        'Press up again to clear your head and return it to the front, keeping the bar low without locking out.',
      ],
      formChecks: [
        'Press just over your head, no lockout',
        'Alternate front and behind the neck',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ZNZiNpR4oUg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Bradford_Press/0.jpg',
    ),
    'Standing_Military_Press': ExerciseCoaching(
      howTo: [
        'Hold the bar at the front of the shoulders, feet hip-width, glutes and abs braced.',
        'Press the bar overhead, moving the head back slightly to clear it, then push through to a locked-out finish over the mid-foot.',
      ],
      formChecks: [
        'Squeeze the glutes and abs, don\'t lean back',
        'Bar travels in a straight line over the mid-foot',
        'Full lockout with the biceps by the ears',
        'Keep the ribs down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dDNlDr8MXJY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Military_Press/0.jpg',
    ),
    'Standing_Palm-In_One-Arm_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'Hold a dumbbell at one shoulder with a neutral grip, palm facing in, feet shoulder-width.',
        'Hold an incline bench with your free hand for balance.',
        'Press the dumbbell straight overhead until the arm locks, then lower it slowly back to your shoulder.',
      ],
      formChecks: [
        'Keep your palm facing in',
        'Steady on the bench, don\'t push off it',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WDVkcfXPUuA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Palm-In_One-Arm_Dumbbell_Press/0.jpg',
    ),
    'Standing_Palms-In_Dumbbell_Press': ExerciseCoaching(
      howTo: [
        'Stand with a dumbbell at each shoulder using a neutral grip, palms facing each other, feet shoulder-width.',
        'Brace your core and press both dumbbells straight overhead until the arms lock out.',
        'Lower them slowly back to your shoulders.',
      ],
      formChecks: [
        'Keep palms facing each other',
        'Press both bells straight up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kqCXXwgCttQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Standing_Palms-In_Dumbbell_Press/0.jpg',
    ),
    'Two-Arm_Kettlebell_Jerk': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders in the rack position, palms facing forward.',
        'Dip by bending the knees, then drive explosively through the legs to launch the bells up.',
        'Drop under them into a slight squat as the arms lock overhead, then stand tall.',
      ],
      formChecks: [
        'Keep bells racked, dip straight down',
        'Drive through the legs to launch them',
        'Drop under into a quarter squat',
        'Lock both arms overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9NFkYaviXgk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Jerk/0.jpg',
    ),
    'Two-Arm_Kettlebell_Military_Press': ExerciseCoaching(
      howTo: [
        'Clean two kettlebells to your shoulders in the rack position, palms facing forward.',
        'Keep your legs and torso still and press both bells straight overhead until the arms lock out.',
        'Lower them under control back to the rack at your shoulders.',
      ],
      formChecks: [
        'Press strict, no leg drive',
        'Both bells straight overhead',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mLzxYnQ6qrY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Two-Arm_Kettlebell_Military_Press/0.jpg',
    ),
  };

  static List<Exercise> all() => _all;

  static Exercise? findById(String id) {
    for (final exercise in _all) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  static ExerciseCoaching? coachingFor(String id) => _coaching[id];
}
