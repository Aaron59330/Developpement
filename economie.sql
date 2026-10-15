-- Économie réaliste Bluebay : à exécuter UNE FOIS sur une base existante (les nouveaux défauts du code ne touchent pas les données déjà en base).
-- 1 fiche de paie (30 min) = 1 journée de travail net. RSA ≈ 20 $, SMIC ≈ 60 $, cadres 150-300 $.
UPDATE job_grades SET salary = 20 WHERE job_name = 'unemployed';
UPDATE job2_grades SET salary = 0 WHERE job_name = 'unemployed2';
-- Plafonne les salaires trop élevés déjà créés dans le builder (400 = plafond patron)
UPDATE job_grades SET salary = 400 WHERE salary > 400;
UPDATE job2_grades SET salary = 400 WHERE salary > 400;
