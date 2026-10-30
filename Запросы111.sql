-- Задание 1. Выбрать всех персонажей из победивших команд, получивших за раунд больше 50 очков опыта
SELECT DISTINCT 
    c.character_id,
    c.user_id,
    c.character_name,
    c.character_level,   
    rr.is_team_winner AS команда_победила, 
    rr.xp_earned AS полученный_опыт       
FROM characters c
JOIN round_results rr ON c.character_id = rr.character_id AND c.user_id = rr.user_id
WHERE rr.is_team_winner = TRUE 
  AND rr.xp_earned > 50;


-- Задание 2. Выбрать всех пользователей, у которых время нахождения в раунде было меньше 5 минут
SELECT DISTINCT 
    user_id, 
    round_time AS время_в_раунде 
FROM round_results
WHERE round_time < INTERVAL '5 minutes';


-- Задание 3. Создать таблицу, содержащую данные 1 запроса с указанием полученного опыта и времени, проведенного в раундах
SELECT 
    c.character_id,
    c.user_id,
    c.character_name,
    c.character_story,
    c.character_level,
    c.special_skills,
    rr.round_id,
    rr.xp_earned,
    rr.round_time
INTO target_characters_report
FROM characters c
JOIN round_results rr ON c.character_id = rr.character_id AND c.user_id = rr.user_id
WHERE rr.is_team_winner = TRUE 
  AND rr.xp_earned > 50;


-- Задание 4. Добавить в таблицу персонажей, среди умений которых отсутствует скрытность
INSERT INTO target_characters_report (
    character_id, user_id, character_name, character_story, 
    character_level, special_skills, round_id, xp_earned, round_time
)
SELECT 
    c.character_id, c.user_id, c.character_name, c.character_story, 
    c.character_level, c.special_skills, rr.round_id, rr.xp_earned, rr.round_time
FROM characters c
JOIN round_results rr ON c.character_id = rr.character_id AND c.user_id = rr.user_id
WHERE c.special_skills NOT ILIKE '%скрытность%';


-- Задание 5. В созданной таблице обнулить уровень всем персонажам, ни разу не побеждавшим в раундах
UPDATE target_characters_report tcr
SET character_level = 0
WHERE NOT EXISTS (
    SELECT 1 
    FROM round_results rr
    WHERE rr.character_id = tcr.character_id 
      AND rr.user_id = tcr.user_id 
      AND rr.is_team_winner = TRUE
);


-- Задание 6. Удалить из созданной таблицы персонажей с отсутствующей историей
DELETE FROM target_characters_report
WHERE character_story IS NULL 
   OR TRIM(character_story) = '';


-- Задание 7. Посчитать среднее количество получаемых очков опыта в час за время, проведенное в раундах, для каждого персонажа каждого пользователя
SELECT 
    user_id,
    character_id,
    SUM(xp_earned) AS всего_опыта,
    SUM(round_time) AS всего_времени_интервал,
    ROUND(EXTRACT(EPOCH FROM SUM(round_time)) / 3600.0, 2) AS всего_времени_в_часах, 
    CASE 
        WHEN EXTRACT(EPOCH FROM SUM(round_time)) > 0 
        THEN ROUND(SUM(xp_earned) / (EXTRACT(EPOCH FROM SUM(round_time)) / 3600.0), 2)
        ELSE 0 
    END AS средний_опыт_в_час
FROM round_results
GROUP BY user_id, character_id
ORDER BY user_id, character_id;