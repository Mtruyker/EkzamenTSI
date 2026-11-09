# Расширение банка вопросов по лекциям ТСИ

Банк `questions.json` содержит 200 вопросов. Вопросы 1–100 сохранены; вопросы 101–200 добавлены по 33 лекциям из [Mtruyker/tsi-lecture](https://github.com/Mtruyker/tsi-lecture), версия `b8679a74e581e3c7afc89644602c7fe01a8a9b3a`.

Добавлено 68 вопросов с одним ответом (1 балл), 28 с несколькими ответами (2 балла) и 4 с коротким текстовым ответом (2 балла). В заданиях с несколькими ответами нужно выбрать весь правильный набор; частичные баллы не начисляются. Текстовые ответы проверяются по перечисленным в JSON вариантам с нормализацией регистра и пробелов.

Размер билета — 20 случайных вопросов, время — 30 минут. Сервер перемешивает вопросы и варианты; равномерное представительство лекций в отдельном билете не гарантируется. Ссылки и разделы ниже предназначены для преподавателя, не передаются в билет студента. После обновления файла перезапустите сервер между экзаменами, когда нет активных попыток.

## Источники новых вопросов

Ссылки закреплены на изученной версии лекций. Номер раздела позволяет проверить основание ответа. Формулировки и расчётные примеры составлены для банка, а не скопированы из самоконтроля.

| ID | Лекция | Разделы |
| --- | --- | --- |
| 101 | [Лекция 1. Технические средства информатизации](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/01_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 4, 9 |
| 102 | [Лекция 1. Технические средства информатизации](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/01_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 103 | [Лекция 1. Технические средства информатизации](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/01_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 104 | [Лекция 2. Современная архитектура вычислительных систем](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/02_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 105 | [Лекция 2. Современная архитектура вычислительных систем](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/02_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 106 | [Лекция 2. Современная архитектура вычислительных систем](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/02_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 107 | [Лекция 3. Процессоры, ускорители и производительность](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/03_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8, 10 |
| 108 | [Лекция 3. Процессоры, ускорители и производительность](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/03_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 109 | [Лекция 3. Процессоры, ускорители и производительность](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/03_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 110 | [Лекция 4. Материнская плата, UEFI и внутренние интерфейсы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/04_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 111 | [Лекция 4. Материнская плата, UEFI и внутренние интерфейсы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/04_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 112 | [Лекция 4. Материнская плата, UEFI и внутренние интерфейсы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/04_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 113 | [Лекция 5. Иерархия памяти: кэш, DDR5, LPDDR и ECC](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/05_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 114 | [Лекция 5. Иерархия памяти: кэш, DDR5, LPDDR и ECC](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/05_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 115 | [Лекция 5. Иерархия памяти: кэш, DDR5, LPDDR и ECC](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/05_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 116 | [Лекция 6. Накопители и организация хранения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/06_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 117 | [Лекция 6. Накопители и организация хранения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/06_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 118 | [Лекция 6. Накопители и организация хранения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/06_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 119 | [Лекция 7. Питание, охлаждение, корпуса и диагностика](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/07_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 120 | [Лекция 7. Питание, охлаждение, корпуса и диагностика](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/07_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 121 | [Лекция 7. Питание, охлаждение, корпуса и диагностика](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/07_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 122 | [Лекция 8. Устройства ввода и эргономика](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/08_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 123 | [Лекция 8. Устройства ввода и эргономика](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/08_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 124 | [Лекция 8. Устройства ввода и эргономика](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/08_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 125 | [Лекция 9. Сканеры и цифровые камеры](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/09_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 126 | [Лекция 9. Сканеры и цифровые камеры](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/09_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 127 | [Лекция 9. Сканеры и цифровые камеры](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/09_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 128 | [Лекция 10. Графическая подсистема и устройства отображения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/10_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 129 | [Лекция 10. Графическая подсистема и устройства отображения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/10_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 130 | [Лекция 10. Графическая подсистема и устройства отображения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/10_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 131 | [Лекция 11. Печать, копирование и документооборот](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/11_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 132 | [Лекция 11. Печать, копирование и документооборот](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/11_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 133 | [Лекция 11. Печать, копирование и документооборот](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/11_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 134 | [Лекция 12. 3D-печать, 3D-сканирование и иммерсивные системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/12_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 135 | [Лекция 12. 3D-печать, 3D-сканирование и иммерсивные системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/12_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 136 | [Лекция 12. 3D-печать, 3D-сканирование и иммерсивные системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/12_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10, развёрнутый пример |
| 137 | [Лекция 13. Аудио, видео и мультимедийные комплексы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/13_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 138 | [Лекция 13. Аудио, видео и мультимедийные комплексы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/13_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 139 | [Лекция 13. Аудио, видео и мультимедийные комплексы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/13_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 1 |
| 140 | [Лекция 14. Внешние интерфейсы и проводные каналы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/14_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 141 | [Лекция 14. Внешние интерфейсы и проводные каналы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/14_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 142 | [Лекция 14. Внешние интерфейсы и проводные каналы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/14_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 12 |
| 143 | [Лекция 15. Ethernet, TCP/IP и сетевые службы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/15_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 144 | [Лекция 15. Ethernet, TCP/IP и сетевые службы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/15_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 12 |
| 145 | [Лекция 15. Ethernet, TCP/IP и сетевые службы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/15_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 5 |
| 146 | [Лекция 16. Wi‑Fi, Bluetooth и IoT](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/16_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 147 | [Лекция 16. Wi‑Fi, Bluetooth и IoT](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/16_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 148 | [Лекция 16. Wi‑Fi, Bluetooth и IoT](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/16_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 149 | [Лекция 17. 4G, 5G‑Advanced и спутниковая связь](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/17_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 150 | [Лекция 17. 4G, 5G‑Advanced и спутниковая связь](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/17_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 151 | [Лекция 17. 4G, 5G‑Advanced и спутниковая связь](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/17_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 12 |
| 152 | [Лекция 18. Аппаратная безопасность, эксплуатация и жизненный цикл](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/18_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 153 | [Лекция 18. Аппаратная безопасность, эксплуатация и жизненный цикл](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/18_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 154 | [Лекция 18. Аппаратная безопасность, эксплуатация и жизненный цикл](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/18_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 13 |
| 155 | [Лекция 19. Рабочие станции, серверы и тонкие клиенты](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/19_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | развёрнутый пример |
| 156 | [Лекция 19. Рабочие станции, серверы и тонкие клиенты](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/19_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 157 | [Лекция 19. Рабочие станции, серверы и тонкие клиенты](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/19_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 158 | [Лекция 20. Виртуализация и контейнерная инфраструктура](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/20_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 159 | [Лекция 20. Виртуализация и контейнерная инфраструктура](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/20_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 160 | [Лекция 20. Виртуализация и контейнерная инфраструктура](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/20_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 161 | [Лекция 21. NAS, SAN и сетевые системы хранения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/21_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 162 | [Лекция 21. NAS, SAN и сетевые системы хранения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/21_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 163 | [Лекция 21. NAS, SAN и сетевые системы хранения](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/21_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 164 | [Лекция 22. Резервное копирование и аварийное восстановление](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/22_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 5 |
| 165 | [Лекция 22. Резервное копирование и аварийное восстановление](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/22_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 166 | [Лекция 22. Резервное копирование и аварийное восстановление](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/22_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 6, 7, 11 |
| 167 | [Лекция 23. Сетевое оборудование и структурированная кабельная система](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/23_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 168 | [Лекция 23. Сетевое оборудование и структурированная кабельная система](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/23_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 169 | [Лекция 23. Сетевое оборудование и структурированная кабельная система](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/23_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 170 | [Лекция 24. Инструменты сетевой диагностики](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/24_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 171 | [Лекция 24. Инструменты сетевой диагностики](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/24_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 172 | [Лекция 24. Инструменты сетевой диагностики](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/24_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8, 12 |
| 173 | [Лекция 25. Обслуживание принтеров, МФУ и сканеров](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/25_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 174 | [Лекция 25. Обслуживание принтеров, МФУ и сканеров](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/25_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 175 | [Лекция 25. Обслуживание принтеров, МФУ и сканеров](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/25_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 176 | [Лекция 26. Видеонаблюдение и контроль доступа](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/26_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 177 | [Лекция 26. Видеонаблюдение и контроль доступа](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/26_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 178 | [Лекция 26. Видеонаблюдение и контроль доступа](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/26_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 179 | [Лекция 27. Датчики, контроллеры и Интернет вещей](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/27_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 180 | [Лекция 27. Датчики, контроллеры и Интернет вещей](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/27_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | развёрнутый пример |
| 181 | [Лекция 27. Датчики, контроллеры и Интернет вещей](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/27_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 182 | [Лекция 28. Мобильные устройства и управление парком](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/28_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 183 | [Лекция 28. Мобильные устройства и управление парком](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/28_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 184 | [Лекция 28. Мобильные устройства и управление парком](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/28_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 185 | [Лекция 29. Встраиваемые и промышленные вычислительные системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/29_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 186 | [Лекция 29. Встраиваемые и промышленные вычислительные системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/29_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 187 | [Лекция 29. Встраиваемые и промышленные вычислительные системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/29_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 188 | [Лекция 30. Регламентное обслуживание и ремонт ТСИ](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/30_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 189 | [Лекция 30. Регламентное обслуживание и ремонт ТСИ](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/30_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 190 | [Лекция 30. Регламентное обслуживание и ремонт ТСИ](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/30_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 10 |
| 191 | [Лекция 31. Закупка, приёмка, инвентаризация и TCO](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/31_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 192 | [Лекция 31. Закупка, приёмка, инвентаризация и TCO](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/31_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 193 | [Лекция 31. Закупка, приёмка, инвентаризация и TCO](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/31_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 194 | [Лекция 32. Комплексная диагностика информационной системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/32_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 195 | [Лекция 32. Комплексная диагностика информационной системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/32_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 196 | [Лекция 32. Комплексная диагностика информационной системы](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/32_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |
| 197 | [Лекция 33. Итоговое повторение и защита проекта](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/33_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 7 |
| 198 | [Лекция 33. Итоговое повторение и защита проекта](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/33_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 8 |
| 199 | [Лекция 33. Итоговое повторение и защита проекта](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/33_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 9 |
| 200 | [Лекция 33. Итоговое повторение и защита проекта](https://github.com/Mtruyker/tsi-lecture/blob/b8679a74e581e3c7afc89644602c7fe01a8a9b3a/33_%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F.md) | 11 |

## Проверка

Из папки `server`:

```powershell
go test server.go questions_test.go
```

Проверяются структура банка, уникальность ID и формулировок, ключи ответов, выдача билета и подсчёт баллов для каждого вопроса после перемешивания вариантов.
