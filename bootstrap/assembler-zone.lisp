;;;; bootstrap/assembler-zone.lisp
;;;;
;;;; AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND.
;;;;
;;;; Source space: assembler
;;;; Generator: src/codegen-cl-inline.scm
;;;; Regenerate: make bootstrap/assembler-zone.lisp
;;;;
;;;; The CL runtime loads this file at boot and registers the defun
;;;; below under its space symbol in *compiled-zone-functions*.

(in-package :ece)

(defun zone-assembler (initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)
  (cl:let ((pc initial-pc)
           (val initial-val)
           (env initial-env)
           (proc initial-proc)
           (argl initial-argl)
           (continue initial-continue)
           (stack initial-stack)
           (flag cl:nil))
    (cl:declare (cl:type cl:fixnum pc) (cl:ignorable flag))
    (cl:tagbody
     (cl:cond
       ((cl:< pc 256)
        (cl:case pc
          (0 (cl:go pc-0))
          (1 (cl:go pc-1))
          (2 (cl:go pc-2))
          (3 (cl:go pc-3))
          (4 (cl:go pc-4))
          (5 (cl:go pc-5))
          (6 (cl:go pc-6))
          (7 (cl:go pc-7))
          (8 (cl:go pc-8))
          (9 (cl:go pc-9))
          (10 (cl:go pc-10))
          (11 (cl:go pc-11))
          (12 (cl:go pc-12))
          (13 (cl:go pc-13))
          (14 (cl:go pc-14))
          (15 (cl:go pc-15))
          (16 (cl:go pc-16))
          (17 (cl:go pc-17))
          (18 (cl:go pc-18))
          (19 (cl:go pc-19))
          (20 (cl:go pc-20))
          (21 (cl:go pc-21))
          (22 (cl:go pc-22))
          (23 (cl:go pc-23))
          (24 (cl:go pc-24))
          (25 (cl:go pc-25))
          (26 (cl:go pc-26))
          (27 (cl:go pc-27))
          (28 (cl:go pc-28))
          (29 (cl:go pc-29))
          (30 (cl:go pc-30))
          (31 (cl:go pc-31))
          (32 (cl:go pc-32))
          (33 (cl:go pc-33))
          (34 (cl:go pc-34))
          (35 (cl:go pc-35))
          (36 (cl:go pc-36))
          (37 (cl:go pc-37))
          (38 (cl:go pc-38))
          (39 (cl:go pc-39))
          (40 (cl:go pc-40))
          (41 (cl:go pc-41))
          (42 (cl:go pc-42))
          (43 (cl:go pc-43))
          (44 (cl:go pc-44))
          (45 (cl:go pc-45))
          (46 (cl:go pc-46))
          (47 (cl:go pc-47))
          (48 (cl:go pc-48))
          (49 (cl:go pc-49))
          (50 (cl:go pc-50))
          (51 (cl:go pc-51))
          (52 (cl:go pc-52))
          (53 (cl:go pc-53))
          (54 (cl:go pc-54))
          (55 (cl:go pc-55))
          (56 (cl:go pc-56))
          (57 (cl:go pc-57))
          (58 (cl:go pc-58))
          (59 (cl:go pc-59))
          (60 (cl:go pc-60))
          (61 (cl:go pc-61))
          (62 (cl:go pc-62))
          (63 (cl:go pc-63))
          (64 (cl:go pc-64))
          (65 (cl:go pc-65))
          (66 (cl:go pc-66))
          (67 (cl:go pc-67))
          (68 (cl:go pc-68))
          (69 (cl:go pc-69))
          (70 (cl:go pc-70))
          (71 (cl:go pc-71))
          (72 (cl:go pc-72))
          (73 (cl:go pc-73))
          (74 (cl:go pc-74))
          (75 (cl:go pc-75))
          (76 (cl:go pc-76))
          (77 (cl:go pc-77))
          (78 (cl:go pc-78))
          (79 (cl:go pc-79))
          (80 (cl:go pc-80))
          (81 (cl:go pc-81))
          (82 (cl:go pc-82))
          (83 (cl:go pc-83))
          (84 (cl:go pc-84))
          (85 (cl:go pc-85))
          (86 (cl:go pc-86))
          (87 (cl:go pc-87))
          (88 (cl:go pc-88))
          (89 (cl:go pc-89))
          (90 (cl:go pc-90))
          (91 (cl:go pc-91))
          (92 (cl:go pc-92))
          (93 (cl:go pc-93))
          (94 (cl:go pc-94))
          (95 (cl:go pc-95))
          (96 (cl:go pc-96))
          (97 (cl:go pc-97))
          (98 (cl:go pc-98))
          (99 (cl:go pc-99))
          (100 (cl:go pc-100))
          (101 (cl:go pc-101))
          (102 (cl:go pc-102))
          (103 (cl:go pc-103))
          (104 (cl:go pc-104))
          (105 (cl:go pc-105))
          (106 (cl:go pc-106))
          (107 (cl:go pc-107))
          (108 (cl:go pc-108))
          (109 (cl:go pc-109))
          (110 (cl:go pc-110))
          (111 (cl:go pc-111))
          (112 (cl:go pc-112))
          (113 (cl:go pc-113))
          (114 (cl:go pc-114))
          (115 (cl:go pc-115))
          (116 (cl:go pc-116))
          (117 (cl:go pc-117))
          (118 (cl:go pc-118))
          (119 (cl:go pc-119))
          (120 (cl:go pc-120))
          (121 (cl:go pc-121))
          (122 (cl:go pc-122))
          (123 (cl:go pc-123))
          (124 (cl:go pc-124))
          (125 (cl:go pc-125))
          (126 (cl:go pc-126))
          (127 (cl:go pc-127))
          (128 (cl:go pc-128))
          (129 (cl:go pc-129))
          (130 (cl:go pc-130))
          (131 (cl:go pc-131))
          (132 (cl:go pc-132))
          (133 (cl:go pc-133))
          (134 (cl:go pc-134))
          (135 (cl:go pc-135))
          (136 (cl:go pc-136))
          (137 (cl:go pc-137))
          (138 (cl:go pc-138))
          (139 (cl:go pc-139))
          (140 (cl:go pc-140))
          (141 (cl:go pc-141))
          (142 (cl:go pc-142))
          (143 (cl:go pc-143))
          (144 (cl:go pc-144))
          (145 (cl:go pc-145))
          (146 (cl:go pc-146))
          (147 (cl:go pc-147))
          (148 (cl:go pc-148))
          (149 (cl:go pc-149))
          (150 (cl:go pc-150))
          (151 (cl:go pc-151))
          (152 (cl:go pc-152))
          (153 (cl:go pc-153))
          (154 (cl:go pc-154))
          (155 (cl:go pc-155))
          (156 (cl:go pc-156))
          (157 (cl:go pc-157))
          (158 (cl:go pc-158))
          (159 (cl:go pc-159))
          (160 (cl:go pc-160))
          (161 (cl:go pc-161))
          (162 (cl:go pc-162))
          (163 (cl:go pc-163))
          (164 (cl:go pc-164))
          (165 (cl:go pc-165))
          (166 (cl:go pc-166))
          (167 (cl:go pc-167))
          (168 (cl:go pc-168))
          (169 (cl:go pc-169))
          (170 (cl:go pc-170))
          (171 (cl:go pc-171))
          (172 (cl:go pc-172))
          (173 (cl:go pc-173))
          (174 (cl:go pc-174))
          (175 (cl:go pc-175))
          (176 (cl:go pc-176))
          (177 (cl:go pc-177))
          (178 (cl:go pc-178))
          (179 (cl:go pc-179))
          (180 (cl:go pc-180))
          (181 (cl:go pc-181))
          (182 (cl:go pc-182))
          (183 (cl:go pc-183))
          (184 (cl:go pc-184))
          (185 (cl:go pc-185))
          (186 (cl:go pc-186))
          (187 (cl:go pc-187))
          (188 (cl:go pc-188))
          (189 (cl:go pc-189))
          (190 (cl:go pc-190))
          (191 (cl:go pc-191))
          (192 (cl:go pc-192))
          (193 (cl:go pc-193))
          (194 (cl:go pc-194))
          (195 (cl:go pc-195))
          (196 (cl:go pc-196))
          (197 (cl:go pc-197))
          (198 (cl:go pc-198))
          (199 (cl:go pc-199))
          (200 (cl:go pc-200))
          (201 (cl:go pc-201))
          (202 (cl:go pc-202))
          (203 (cl:go pc-203))
          (204 (cl:go pc-204))
          (205 (cl:go pc-205))
          (206 (cl:go pc-206))
          (207 (cl:go pc-207))
          (208 (cl:go pc-208))
          (209 (cl:go pc-209))
          (210 (cl:go pc-210))
          (211 (cl:go pc-211))
          (212 (cl:go pc-212))
          (213 (cl:go pc-213))
          (214 (cl:go pc-214))
          (215 (cl:go pc-215))
          (216 (cl:go pc-216))
          (217 (cl:go pc-217))
          (218 (cl:go pc-218))
          (219 (cl:go pc-219))
          (220 (cl:go pc-220))
          (221 (cl:go pc-221))
          (222 (cl:go pc-222))
          (223 (cl:go pc-223))
          (224 (cl:go pc-224))
          (225 (cl:go pc-225))
          (226 (cl:go pc-226))
          (227 (cl:go pc-227))
          (228 (cl:go pc-228))
          (229 (cl:go pc-229))
          (230 (cl:go pc-230))
          (231 (cl:go pc-231))
          (232 (cl:go pc-232))
          (233 (cl:go pc-233))
          (234 (cl:go pc-234))
          (235 (cl:go pc-235))
          (236 (cl:go pc-236))
          (237 (cl:go pc-237))
          (238 (cl:go pc-238))
          (239 (cl:go pc-239))
          (240 (cl:go pc-240))
          (241 (cl:go pc-241))
          (242 (cl:go pc-242))
          (243 (cl:go pc-243))
          (244 (cl:go pc-244))
          (245 (cl:go pc-245))
          (246 (cl:go pc-246))
          (247 (cl:go pc-247))
          (248 (cl:go pc-248))
          (249 (cl:go pc-249))
          (250 (cl:go pc-250))
          (251 (cl:go pc-251))
          (252 (cl:go pc-252))
          (253 (cl:go pc-253))
          (254 (cl:go pc-254))
          (255 (cl:go pc-255))
          (cl:t (cl:go zone-exit))))
       ((cl:< pc 512)
        (cl:case pc
          (256 (cl:go pc-256))
          (257 (cl:go pc-257))
          (258 (cl:go pc-258))
          (259 (cl:go pc-259))
          (260 (cl:go pc-260))
          (261 (cl:go pc-261))
          (262 (cl:go pc-262))
          (263 (cl:go pc-263))
          (264 (cl:go pc-264))
          (265 (cl:go pc-265))
          (266 (cl:go pc-266))
          (267 (cl:go pc-267))
          (268 (cl:go pc-268))
          (269 (cl:go pc-269))
          (270 (cl:go pc-270))
          (271 (cl:go pc-271))
          (272 (cl:go pc-272))
          (273 (cl:go pc-273))
          (274 (cl:go pc-274))
          (275 (cl:go pc-275))
          (276 (cl:go pc-276))
          (277 (cl:go pc-277))
          (278 (cl:go pc-278))
          (279 (cl:go pc-279))
          (280 (cl:go pc-280))
          (281 (cl:go pc-281))
          (282 (cl:go pc-282))
          (283 (cl:go pc-283))
          (284 (cl:go pc-284))
          (285 (cl:go pc-285))
          (286 (cl:go pc-286))
          (287 (cl:go pc-287))
          (288 (cl:go pc-288))
          (289 (cl:go pc-289))
          (290 (cl:go pc-290))
          (291 (cl:go pc-291))
          (292 (cl:go pc-292))
          (293 (cl:go pc-293))
          (294 (cl:go pc-294))
          (295 (cl:go pc-295))
          (296 (cl:go pc-296))
          (297 (cl:go pc-297))
          (298 (cl:go pc-298))
          (299 (cl:go pc-299))
          (300 (cl:go pc-300))
          (301 (cl:go pc-301))
          (302 (cl:go pc-302))
          (303 (cl:go pc-303))
          (304 (cl:go pc-304))
          (305 (cl:go pc-305))
          (306 (cl:go pc-306))
          (307 (cl:go pc-307))
          (308 (cl:go pc-308))
          (309 (cl:go pc-309))
          (310 (cl:go pc-310))
          (311 (cl:go pc-311))
          (312 (cl:go pc-312))
          (313 (cl:go pc-313))
          (314 (cl:go pc-314))
          (315 (cl:go pc-315))
          (316 (cl:go pc-316))
          (317 (cl:go pc-317))
          (318 (cl:go pc-318))
          (319 (cl:go pc-319))
          (320 (cl:go pc-320))
          (321 (cl:go pc-321))
          (322 (cl:go pc-322))
          (323 (cl:go pc-323))
          (324 (cl:go pc-324))
          (325 (cl:go pc-325))
          (326 (cl:go pc-326))
          (327 (cl:go pc-327))
          (328 (cl:go pc-328))
          (329 (cl:go pc-329))
          (330 (cl:go pc-330))
          (331 (cl:go pc-331))
          (332 (cl:go pc-332))
          (333 (cl:go pc-333))
          (334 (cl:go pc-334))
          (335 (cl:go pc-335))
          (336 (cl:go pc-336))
          (337 (cl:go pc-337))
          (338 (cl:go pc-338))
          (339 (cl:go pc-339))
          (340 (cl:go pc-340))
          (341 (cl:go pc-341))
          (342 (cl:go pc-342))
          (343 (cl:go pc-343))
          (344 (cl:go pc-344))
          (345 (cl:go pc-345))
          (346 (cl:go pc-346))
          (347 (cl:go pc-347))
          (348 (cl:go pc-348))
          (349 (cl:go pc-349))
          (350 (cl:go pc-350))
          (351 (cl:go pc-351))
          (352 (cl:go pc-352))
          (353 (cl:go pc-353))
          (354 (cl:go pc-354))
          (355 (cl:go pc-355))
          (356 (cl:go pc-356))
          (357 (cl:go pc-357))
          (358 (cl:go pc-358))
          (359 (cl:go pc-359))
          (360 (cl:go pc-360))
          (361 (cl:go pc-361))
          (362 (cl:go pc-362))
          (363 (cl:go pc-363))
          (364 (cl:go pc-364))
          (365 (cl:go pc-365))
          (366 (cl:go pc-366))
          (367 (cl:go pc-367))
          (368 (cl:go pc-368))
          (369 (cl:go pc-369))
          (370 (cl:go pc-370))
          (371 (cl:go pc-371))
          (372 (cl:go pc-372))
          (373 (cl:go pc-373))
          (374 (cl:go pc-374))
          (375 (cl:go pc-375))
          (376 (cl:go pc-376))
          (377 (cl:go pc-377))
          (378 (cl:go pc-378))
          (379 (cl:go pc-379))
          (380 (cl:go pc-380))
          (381 (cl:go pc-381))
          (382 (cl:go pc-382))
          (383 (cl:go pc-383))
          (384 (cl:go pc-384))
          (385 (cl:go pc-385))
          (386 (cl:go pc-386))
          (387 (cl:go pc-387))
          (388 (cl:go pc-388))
          (389 (cl:go pc-389))
          (390 (cl:go pc-390))
          (391 (cl:go pc-391))
          (392 (cl:go pc-392))
          (393 (cl:go pc-393))
          (394 (cl:go pc-394))
          (395 (cl:go pc-395))
          (396 (cl:go pc-396))
          (397 (cl:go pc-397))
          (398 (cl:go pc-398))
          (399 (cl:go pc-399))
          (400 (cl:go pc-400))
          (401 (cl:go pc-401))
          (402 (cl:go pc-402))
          (403 (cl:go pc-403))
          (404 (cl:go pc-404))
          (405 (cl:go pc-405))
          (406 (cl:go pc-406))
          (407 (cl:go pc-407))
          (408 (cl:go pc-408))
          (409 (cl:go pc-409))
          (410 (cl:go pc-410))
          (411 (cl:go pc-411))
          (412 (cl:go pc-412))
          (413 (cl:go pc-413))
          (414 (cl:go pc-414))
          (415 (cl:go pc-415))
          (416 (cl:go pc-416))
          (417 (cl:go pc-417))
          (418 (cl:go pc-418))
          (419 (cl:go pc-419))
          (420 (cl:go pc-420))
          (421 (cl:go pc-421))
          (422 (cl:go pc-422))
          (423 (cl:go pc-423))
          (424 (cl:go pc-424))
          (425 (cl:go pc-425))
          (426 (cl:go pc-426))
          (427 (cl:go pc-427))
          (428 (cl:go pc-428))
          (429 (cl:go pc-429))
          (430 (cl:go pc-430))
          (431 (cl:go pc-431))
          (432 (cl:go pc-432))
          (433 (cl:go pc-433))
          (434 (cl:go pc-434))
          (435 (cl:go pc-435))
          (436 (cl:go pc-436))
          (437 (cl:go pc-437))
          (438 (cl:go pc-438))
          (439 (cl:go pc-439))
          (440 (cl:go pc-440))
          (441 (cl:go pc-441))
          (442 (cl:go pc-442))
          (443 (cl:go pc-443))
          (444 (cl:go pc-444))
          (445 (cl:go pc-445))
          (446 (cl:go pc-446))
          (447 (cl:go pc-447))
          (448 (cl:go pc-448))
          (449 (cl:go pc-449))
          (450 (cl:go pc-450))
          (451 (cl:go pc-451))
          (452 (cl:go pc-452))
          (453 (cl:go pc-453))
          (454 (cl:go pc-454))
          (455 (cl:go pc-455))
          (456 (cl:go pc-456))
          (457 (cl:go pc-457))
          (458 (cl:go pc-458))
          (459 (cl:go pc-459))
          (460 (cl:go pc-460))
          (461 (cl:go pc-461))
          (462 (cl:go pc-462))
          (463 (cl:go pc-463))
          (464 (cl:go pc-464))
          (465 (cl:go pc-465))
          (466 (cl:go pc-466))
          (467 (cl:go pc-467))
          (468 (cl:go pc-468))
          (469 (cl:go pc-469))
          (470 (cl:go pc-470))
          (471 (cl:go pc-471))
          (472 (cl:go pc-472))
          (473 (cl:go pc-473))
          (474 (cl:go pc-474))
          (475 (cl:go pc-475))
          (476 (cl:go pc-476))
          (477 (cl:go pc-477))
          (478 (cl:go pc-478))
          (479 (cl:go pc-479))
          (480 (cl:go pc-480))
          (481 (cl:go pc-481))
          (482 (cl:go pc-482))
          (483 (cl:go pc-483))
          (484 (cl:go pc-484))
          (485 (cl:go pc-485))
          (486 (cl:go pc-486))
          (487 (cl:go pc-487))
          (488 (cl:go pc-488))
          (489 (cl:go pc-489))
          (490 (cl:go pc-490))
          (491 (cl:go pc-491))
          (492 (cl:go pc-492))
          (493 (cl:go pc-493))
          (494 (cl:go pc-494))
          (495 (cl:go pc-495))
          (496 (cl:go pc-496))
          (497 (cl:go pc-497))
          (498 (cl:go pc-498))
          (499 (cl:go pc-499))
          (500 (cl:go pc-500))
          (501 (cl:go pc-501))
          (502 (cl:go pc-502))
          (503 (cl:go pc-503))
          (504 (cl:go pc-504))
          (505 (cl:go pc-505))
          (506 (cl:go pc-506))
          (507 (cl:go pc-507))
          (508 (cl:go pc-508))
          (509 (cl:go pc-509))
          (510 (cl:go pc-510))
          (511 (cl:go pc-511))
          (cl:t (cl:go zone-exit))))
       ((cl:< pc 768)
        (cl:case pc
          (512 (cl:go pc-512))
          (513 (cl:go pc-513))
          (514 (cl:go pc-514))
          (515 (cl:go pc-515))
          (516 (cl:go pc-516))
          (517 (cl:go pc-517))
          (518 (cl:go pc-518))
          (519 (cl:go pc-519))
          (520 (cl:go pc-520))
          (521 (cl:go pc-521))
          (522 (cl:go pc-522))
          (523 (cl:go pc-523))
          (524 (cl:go pc-524))
          (525 (cl:go pc-525))
          (526 (cl:go pc-526))
          (527 (cl:go pc-527))
          (528 (cl:go pc-528))
          (529 (cl:go pc-529))
          (530 (cl:go pc-530))
          (531 (cl:go pc-531))
          (532 (cl:go pc-532))
          (533 (cl:go pc-533))
          (534 (cl:go pc-534))
          (535 (cl:go pc-535))
          (536 (cl:go pc-536))
          (537 (cl:go pc-537))
          (538 (cl:go pc-538))
          (539 (cl:go pc-539))
          (540 (cl:go pc-540))
          (541 (cl:go pc-541))
          (542 (cl:go pc-542))
          (543 (cl:go pc-543))
          (544 (cl:go pc-544))
          (545 (cl:go pc-545))
          (546 (cl:go pc-546))
          (547 (cl:go pc-547))
          (548 (cl:go pc-548))
          (549 (cl:go pc-549))
          (550 (cl:go pc-550))
          (551 (cl:go pc-551))
          (552 (cl:go pc-552))
          (553 (cl:go pc-553))
          (554 (cl:go pc-554))
          (555 (cl:go pc-555))
          (556 (cl:go pc-556))
          (557 (cl:go pc-557))
          (558 (cl:go pc-558))
          (559 (cl:go pc-559))
          (560 (cl:go pc-560))
          (561 (cl:go pc-561))
          (562 (cl:go pc-562))
          (563 (cl:go pc-563))
          (564 (cl:go pc-564))
          (565 (cl:go pc-565))
          (566 (cl:go pc-566))
          (567 (cl:go pc-567))
          (568 (cl:go pc-568))
          (569 (cl:go pc-569))
          (570 (cl:go pc-570))
          (571 (cl:go pc-571))
          (572 (cl:go pc-572))
          (573 (cl:go pc-573))
          (574 (cl:go pc-574))
          (575 (cl:go pc-575))
          (576 (cl:go pc-576))
          (577 (cl:go pc-577))
          (578 (cl:go pc-578))
          (579 (cl:go pc-579))
          (580 (cl:go pc-580))
          (581 (cl:go pc-581))
          (582 (cl:go pc-582))
          (583 (cl:go pc-583))
          (584 (cl:go pc-584))
          (585 (cl:go pc-585))
          (586 (cl:go pc-586))
          (587 (cl:go pc-587))
          (588 (cl:go pc-588))
          (589 (cl:go pc-589))
          (590 (cl:go pc-590))
          (591 (cl:go pc-591))
          (592 (cl:go pc-592))
          (593 (cl:go pc-593))
          (594 (cl:go pc-594))
          (595 (cl:go pc-595))
          (596 (cl:go pc-596))
          (597 (cl:go pc-597))
          (598 (cl:go pc-598))
          (599 (cl:go pc-599))
          (600 (cl:go pc-600))
          (601 (cl:go pc-601))
          (602 (cl:go pc-602))
          (603 (cl:go pc-603))
          (604 (cl:go pc-604))
          (605 (cl:go pc-605))
          (606 (cl:go pc-606))
          (607 (cl:go pc-607))
          (608 (cl:go pc-608))
          (609 (cl:go pc-609))
          (610 (cl:go pc-610))
          (611 (cl:go pc-611))
          (612 (cl:go pc-612))
          (613 (cl:go pc-613))
          (614 (cl:go pc-614))
          (615 (cl:go pc-615))
          (616 (cl:go pc-616))
          (617 (cl:go pc-617))
          (618 (cl:go pc-618))
          (619 (cl:go pc-619))
          (620 (cl:go pc-620))
          (621 (cl:go pc-621))
          (622 (cl:go pc-622))
          (623 (cl:go pc-623))
          (624 (cl:go pc-624))
          (625 (cl:go pc-625))
          (626 (cl:go pc-626))
          (627 (cl:go pc-627))
          (628 (cl:go pc-628))
          (629 (cl:go pc-629))
          (630 (cl:go pc-630))
          (631 (cl:go pc-631))
          (632 (cl:go pc-632))
          (633 (cl:go pc-633))
          (634 (cl:go pc-634))
          (635 (cl:go pc-635))
          (636 (cl:go pc-636))
          (637 (cl:go pc-637))
          (638 (cl:go pc-638))
          (639 (cl:go pc-639))
          (640 (cl:go pc-640))
          (641 (cl:go pc-641))
          (642 (cl:go pc-642))
          (643 (cl:go pc-643))
          (644 (cl:go pc-644))
          (645 (cl:go pc-645))
          (646 (cl:go pc-646))
          (647 (cl:go pc-647))
          (648 (cl:go pc-648))
          (649 (cl:go pc-649))
          (650 (cl:go pc-650))
          (651 (cl:go pc-651))
          (652 (cl:go pc-652))
          (653 (cl:go pc-653))
          (654 (cl:go pc-654))
          (655 (cl:go pc-655))
          (656 (cl:go pc-656))
          (657 (cl:go pc-657))
          (658 (cl:go pc-658))
          (659 (cl:go pc-659))
          (660 (cl:go pc-660))
          (661 (cl:go pc-661))
          (662 (cl:go pc-662))
          (663 (cl:go pc-663))
          (664 (cl:go pc-664))
          (665 (cl:go pc-665))
          (666 (cl:go pc-666))
          (667 (cl:go pc-667))
          (668 (cl:go pc-668))
          (669 (cl:go pc-669))
          (670 (cl:go pc-670))
          (671 (cl:go pc-671))
          (672 (cl:go pc-672))
          (673 (cl:go pc-673))
          (674 (cl:go pc-674))
          (675 (cl:go pc-675))
          (676 (cl:go pc-676))
          (677 (cl:go pc-677))
          (678 (cl:go pc-678))
          (679 (cl:go pc-679))
          (680 (cl:go pc-680))
          (681 (cl:go pc-681))
          (682 (cl:go pc-682))
          (683 (cl:go pc-683))
          (684 (cl:go pc-684))
          (685 (cl:go pc-685))
          (686 (cl:go pc-686))
          (687 (cl:go pc-687))
          (688 (cl:go pc-688))
          (689 (cl:go pc-689))
          (690 (cl:go pc-690))
          (691 (cl:go pc-691))
          (692 (cl:go pc-692))
          (693 (cl:go pc-693))
          (694 (cl:go pc-694))
          (695 (cl:go pc-695))
          (696 (cl:go pc-696))
          (697 (cl:go pc-697))
          (698 (cl:go pc-698))
          (699 (cl:go pc-699))
          (700 (cl:go pc-700))
          (701 (cl:go pc-701))
          (702 (cl:go pc-702))
          (703 (cl:go pc-703))
          (704 (cl:go pc-704))
          (705 (cl:go pc-705))
          (706 (cl:go pc-706))
          (707 (cl:go pc-707))
          (708 (cl:go pc-708))
          (709 (cl:go pc-709))
          (710 (cl:go pc-710))
          (711 (cl:go pc-711))
          (712 (cl:go pc-712))
          (713 (cl:go pc-713))
          (714 (cl:go pc-714))
          (715 (cl:go pc-715))
          (716 (cl:go pc-716))
          (717 (cl:go pc-717))
          (718 (cl:go pc-718))
          (719 (cl:go pc-719))
          (720 (cl:go pc-720))
          (721 (cl:go pc-721))
          (722 (cl:go pc-722))
          (723 (cl:go pc-723))
          (724 (cl:go pc-724))
          (725 (cl:go pc-725))
          (726 (cl:go pc-726))
          (727 (cl:go pc-727))
          (728 (cl:go pc-728))
          (729 (cl:go pc-729))
          (730 (cl:go pc-730))
          (731 (cl:go pc-731))
          (732 (cl:go pc-732))
          (733 (cl:go pc-733))
          (734 (cl:go pc-734))
          (735 (cl:go pc-735))
          (736 (cl:go pc-736))
          (737 (cl:go pc-737))
          (738 (cl:go pc-738))
          (739 (cl:go pc-739))
          (740 (cl:go pc-740))
          (741 (cl:go pc-741))
          (742 (cl:go pc-742))
          (743 (cl:go pc-743))
          (744 (cl:go pc-744))
          (745 (cl:go pc-745))
          (746 (cl:go pc-746))
          (747 (cl:go pc-747))
          (748 (cl:go pc-748))
          (749 (cl:go pc-749))
          (750 (cl:go pc-750))
          (751 (cl:go pc-751))
          (752 (cl:go pc-752))
          (753 (cl:go pc-753))
          (754 (cl:go pc-754))
          (755 (cl:go pc-755))
          (756 (cl:go pc-756))
          (757 (cl:go pc-757))
          (758 (cl:go pc-758))
          (759 (cl:go pc-759))
          (760 (cl:go pc-760))
          (761 (cl:go pc-761))
          (762 (cl:go pc-762))
          (763 (cl:go pc-763))
          (764 (cl:go pc-764))
          (765 (cl:go pc-765))
          (766 (cl:go pc-766))
          (767 (cl:go pc-767))
          (cl:t (cl:go zone-exit))))
       ((cl:< pc 962)
        (cl:case pc
          (768 (cl:go pc-768))
          (769 (cl:go pc-769))
          (770 (cl:go pc-770))
          (771 (cl:go pc-771))
          (772 (cl:go pc-772))
          (773 (cl:go pc-773))
          (774 (cl:go pc-774))
          (775 (cl:go pc-775))
          (776 (cl:go pc-776))
          (777 (cl:go pc-777))
          (778 (cl:go pc-778))
          (779 (cl:go pc-779))
          (780 (cl:go pc-780))
          (781 (cl:go pc-781))
          (782 (cl:go pc-782))
          (783 (cl:go pc-783))
          (784 (cl:go pc-784))
          (785 (cl:go pc-785))
          (786 (cl:go pc-786))
          (787 (cl:go pc-787))
          (788 (cl:go pc-788))
          (789 (cl:go pc-789))
          (790 (cl:go pc-790))
          (791 (cl:go pc-791))
          (792 (cl:go pc-792))
          (793 (cl:go pc-793))
          (794 (cl:go pc-794))
          (795 (cl:go pc-795))
          (796 (cl:go pc-796))
          (797 (cl:go pc-797))
          (798 (cl:go pc-798))
          (799 (cl:go pc-799))
          (800 (cl:go pc-800))
          (801 (cl:go pc-801))
          (802 (cl:go pc-802))
          (803 (cl:go pc-803))
          (804 (cl:go pc-804))
          (805 (cl:go pc-805))
          (806 (cl:go pc-806))
          (807 (cl:go pc-807))
          (808 (cl:go pc-808))
          (809 (cl:go pc-809))
          (810 (cl:go pc-810))
          (811 (cl:go pc-811))
          (812 (cl:go pc-812))
          (813 (cl:go pc-813))
          (814 (cl:go pc-814))
          (815 (cl:go pc-815))
          (816 (cl:go pc-816))
          (817 (cl:go pc-817))
          (818 (cl:go pc-818))
          (819 (cl:go pc-819))
          (820 (cl:go pc-820))
          (821 (cl:go pc-821))
          (822 (cl:go pc-822))
          (823 (cl:go pc-823))
          (824 (cl:go pc-824))
          (825 (cl:go pc-825))
          (826 (cl:go pc-826))
          (827 (cl:go pc-827))
          (828 (cl:go pc-828))
          (829 (cl:go pc-829))
          (830 (cl:go pc-830))
          (831 (cl:go pc-831))
          (832 (cl:go pc-832))
          (833 (cl:go pc-833))
          (834 (cl:go pc-834))
          (835 (cl:go pc-835))
          (836 (cl:go pc-836))
          (837 (cl:go pc-837))
          (838 (cl:go pc-838))
          (839 (cl:go pc-839))
          (840 (cl:go pc-840))
          (841 (cl:go pc-841))
          (842 (cl:go pc-842))
          (843 (cl:go pc-843))
          (844 (cl:go pc-844))
          (845 (cl:go pc-845))
          (846 (cl:go pc-846))
          (847 (cl:go pc-847))
          (848 (cl:go pc-848))
          (849 (cl:go pc-849))
          (850 (cl:go pc-850))
          (851 (cl:go pc-851))
          (852 (cl:go pc-852))
          (853 (cl:go pc-853))
          (854 (cl:go pc-854))
          (855 (cl:go pc-855))
          (856 (cl:go pc-856))
          (857 (cl:go pc-857))
          (858 (cl:go pc-858))
          (859 (cl:go pc-859))
          (860 (cl:go pc-860))
          (861 (cl:go pc-861))
          (862 (cl:go pc-862))
          (863 (cl:go pc-863))
          (864 (cl:go pc-864))
          (865 (cl:go pc-865))
          (866 (cl:go pc-866))
          (867 (cl:go pc-867))
          (868 (cl:go pc-868))
          (869 (cl:go pc-869))
          (870 (cl:go pc-870))
          (871 (cl:go pc-871))
          (872 (cl:go pc-872))
          (873 (cl:go pc-873))
          (874 (cl:go pc-874))
          (875 (cl:go pc-875))
          (876 (cl:go pc-876))
          (877 (cl:go pc-877))
          (878 (cl:go pc-878))
          (879 (cl:go pc-879))
          (880 (cl:go pc-880))
          (881 (cl:go pc-881))
          (882 (cl:go pc-882))
          (883 (cl:go pc-883))
          (884 (cl:go pc-884))
          (885 (cl:go pc-885))
          (886 (cl:go pc-886))
          (887 (cl:go pc-887))
          (888 (cl:go pc-888))
          (889 (cl:go pc-889))
          (890 (cl:go pc-890))
          (891 (cl:go pc-891))
          (892 (cl:go pc-892))
          (893 (cl:go pc-893))
          (894 (cl:go pc-894))
          (895 (cl:go pc-895))
          (896 (cl:go pc-896))
          (897 (cl:go pc-897))
          (898 (cl:go pc-898))
          (899 (cl:go pc-899))
          (900 (cl:go pc-900))
          (901 (cl:go pc-901))
          (902 (cl:go pc-902))
          (903 (cl:go pc-903))
          (904 (cl:go pc-904))
          (905 (cl:go pc-905))
          (906 (cl:go pc-906))
          (907 (cl:go pc-907))
          (908 (cl:go pc-908))
          (909 (cl:go pc-909))
          (910 (cl:go pc-910))
          (911 (cl:go pc-911))
          (912 (cl:go pc-912))
          (913 (cl:go pc-913))
          (914 (cl:go pc-914))
          (915 (cl:go pc-915))
          (916 (cl:go pc-916))
          (917 (cl:go pc-917))
          (918 (cl:go pc-918))
          (919 (cl:go pc-919))
          (920 (cl:go pc-920))
          (921 (cl:go pc-921))
          (922 (cl:go pc-922))
          (923 (cl:go pc-923))
          (924 (cl:go pc-924))
          (925 (cl:go pc-925))
          (926 (cl:go pc-926))
          (927 (cl:go pc-927))
          (928 (cl:go pc-928))
          (929 (cl:go pc-929))
          (930 (cl:go pc-930))
          (931 (cl:go pc-931))
          (932 (cl:go pc-932))
          (933 (cl:go pc-933))
          (934 (cl:go pc-934))
          (935 (cl:go pc-935))
          (936 (cl:go pc-936))
          (937 (cl:go pc-937))
          (938 (cl:go pc-938))
          (939 (cl:go pc-939))
          (940 (cl:go pc-940))
          (941 (cl:go pc-941))
          (942 (cl:go pc-942))
          (943 (cl:go pc-943))
          (944 (cl:go pc-944))
          (945 (cl:go pc-945))
          (946 (cl:go pc-946))
          (947 (cl:go pc-947))
          (948 (cl:go pc-948))
          (949 (cl:go pc-949))
          (950 (cl:go pc-950))
          (951 (cl:go pc-951))
          (952 (cl:go pc-952))
          (953 (cl:go pc-953))
          (954 (cl:go pc-954))
          (955 (cl:go pc-955))
          (956 (cl:go pc-956))
          (957 (cl:go pc-957))
          (958 (cl:go pc-958))
          (959 (cl:go pc-959))
          (960 (cl:go pc-960))
          (961 (cl:go pc-961))
          (cl:t (cl:go zone-exit))))
       (cl:t (cl:go zone-exit)))
     pc-0
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 2 env))
       (cl:setf pc 1)
     pc-1
       (cl:setf pc 546) (cl:go pc-546)
     pc-2
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3)
     pc-3
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|instruction-list|) argl env 0))
       (cl:setf pc 4)
     pc-4
       (cl:setf val "Append instructions to the current space, register labels. Return start PC.")
       (cl:setf pc 5)
     pc-5
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7 env))
       (cl:setf pc 6)
     pc-6
       (cl:setf pc 505) (cl:go pc-505)
     pc-7
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 8)
     pc-8
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|sid|) argl env 0))
       (cl:setf pc 9)
     pc-9
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 11 env))
       (cl:setf pc 10)
     pc-10
       (cl:setf pc 463) (cl:go pc-463)
     pc-11
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 12)
     pc-12
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|start-pc|) argl env 0))
       (cl:setf pc 13)
     pc-13
       (cl:push continue stack)
       (cl:setf pc 14)
     pc-14
       (cl:push env stack)
       (cl:setf pc 15)
     pc-15
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|for-each| env))
       (cl:setf pc 16)
     pc-16
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 17)
     pc-17
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 18)
     pc-18
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 20 env))
       (cl:setf pc 19)
     pc-19
       (cl:setf pc 421) (cl:go pc-421)
     pc-20
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 21)
     pc-21
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|item|) argl env 0))
       (cl:setf pc 22)
     pc-22
       (cl:push continue stack)
       (cl:setf pc 23)
     pc-23
       (cl:push env stack)
       (cl:setf pc 24)
     pc-24
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|symbol?| env))
       (cl:setf pc 25)
     pc-25
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 26)
     pc-26
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 27)
     pc-27
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 28)
     pc-28
       (cl:when flag (cl:setf pc 43) (cl:go pc-43))
     pc-29
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 30)
     pc-30
       (cl:when flag (cl:setf pc 36) (cl:go pc-36))
     pc-31
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 32)
     pc-32
       (cl:when flag (cl:setf pc 41) (cl:go pc-41))
     pc-33
       (cl:setf continue (cl:cons '|assembler| 44))
       (cl:setf pc 34)
     pc-34
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 35)
     pc-35
       (cl:go zone-exit)
     pc-36
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 37)
     pc-37
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 38)
     pc-38
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 39)
     pc-39
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 40)
     pc-40
       (cl:go zone-exit)
     pc-41
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 42)
     pc-42
       (cl:setf pc 44) (cl:go pc-44)
     pc-43
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 44)
     pc-44
       (cl:setf env (cl:pop stack))
       (cl:setf pc 45)
     pc-45
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 46)
     pc-46
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 47)
     pc-47
       (cl:when flag (cl:setf pc 97) (cl:go pc-97))
     pc-48
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%space-label-set!| env))
       (cl:setf pc 49)
     pc-49
       (cl:push continue stack)
       (cl:setf pc 50)
     pc-50
       (cl:push proc stack)
       (cl:setf pc 51)
     pc-51
       (cl:push env stack)
       (cl:setf pc 52)
     pc-52
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%space-instruction-length| env))
       (cl:setf pc 53)
     pc-53
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 54)
     pc-54
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 55)
     pc-55
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 56)
     pc-56
       (cl:when flag (cl:setf pc 71) (cl:go pc-71))
     pc-57
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 58)
     pc-58
       (cl:when flag (cl:setf pc 64) (cl:go pc-64))
     pc-59
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 60)
     pc-60
       (cl:when flag (cl:setf pc 69) (cl:go pc-69))
     pc-61
       (cl:setf continue (cl:cons '|assembler| 72))
       (cl:setf pc 62)
     pc-62
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 63)
     pc-63
       (cl:go zone-exit)
     pc-64
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 65)
     pc-65
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 66)
     pc-66
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 67)
     pc-67
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 68)
     pc-68
       (cl:go zone-exit)
     pc-69
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 70)
     pc-70
       (cl:setf pc 72) (cl:go pc-72)
     pc-71
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 72)
     pc-72
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 73)
     pc-73
       (cl:setf env (cl:pop stack))
       (cl:setf pc 74)
     pc-74
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 75)
     pc-75
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 76)
     pc-76
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 77)
     pc-77
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 78)
     pc-78
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 79)
     pc-79
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 80)
     pc-80
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 81)
     pc-81
       (cl:when flag (cl:setf pc 95) (cl:go pc-95))
     pc-82
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 83)
     pc-83
       (cl:when flag (cl:setf pc 88) (cl:go pc-88))
     pc-84
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 85)
     pc-85
       (cl:when flag (cl:setf pc 93) (cl:go pc-93))
     pc-86
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 87)
     pc-87
       (cl:go zone-exit)
     pc-88
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 89)
     pc-89
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 90)
     pc-90
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 91)
     pc-91
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 92)
     pc-92
       (cl:go zone-exit)
     pc-93
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 94)
     pc-94
       (cl:go zone-exit)
     pc-95
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 96)
     pc-96
       (cl:go zone-exit)
     pc-97
       (cl:push continue stack)
       (cl:setf pc 98)
     pc-98
       (cl:push env stack)
       (cl:setf pc 99)
     pc-99
       (cl:push env stack)
       (cl:setf pc 100)
     pc-100
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 101)
     pc-101
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 102)
     pc-102
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 103)
     pc-103
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 104)
     pc-104
       (cl:when flag (cl:setf pc 119) (cl:go pc-119))
     pc-105
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 106)
     pc-106
       (cl:when flag (cl:setf pc 112) (cl:go pc-112))
     pc-107
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 108)
     pc-108
       (cl:when flag (cl:setf pc 117) (cl:go pc-117))
     pc-109
       (cl:setf continue (cl:cons '|assembler| 120))
       (cl:setf pc 110)
     pc-110
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 111)
     pc-111
       (cl:go zone-exit)
     pc-112
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 113)
     pc-113
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 114)
     pc-114
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 115)
     pc-115
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 116)
     pc-116
       (cl:go zone-exit)
     pc-117
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 118)
     pc-118
       (cl:setf pc 120) (cl:go pc-120)
     pc-119
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 120)
     pc-120
       (cl:setf env (cl:pop stack))
       (cl:setf pc 121)
     pc-121
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 122)
     pc-122
       (cl:when flag (cl:setf pc 169) (cl:go pc-169))
     pc-123
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 124)
     pc-124
       (cl:push proc stack)
       (cl:setf pc 125)
     pc-125
       (cl:setf val '|procedure-name|)
       (cl:setf pc 126)
     pc-126
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 127)
     pc-127
       (cl:push argl stack)
       (cl:setf pc 128)
     pc-128
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 129)
     pc-129
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 130)
     pc-130
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 131)
     pc-131
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 132)
     pc-132
       (cl:when flag (cl:setf pc 147) (cl:go pc-147))
     pc-133
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 134)
     pc-134
       (cl:when flag (cl:setf pc 140) (cl:go pc-140))
     pc-135
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 136)
     pc-136
       (cl:when flag (cl:setf pc 145) (cl:go pc-145))
     pc-137
       (cl:setf continue (cl:cons '|assembler| 148))
       (cl:setf pc 138)
     pc-138
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 139)
     pc-139
       (cl:go zone-exit)
     pc-140
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 141)
     pc-141
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 142)
     pc-142
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 143)
     pc-143
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 144)
     pc-144
       (cl:go zone-exit)
     pc-145
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 146)
     pc-146
       (cl:setf pc 148) (cl:go pc-148)
     pc-147
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 148)
     pc-148
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 149)
     pc-149
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 150)
     pc-150
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 151)
     pc-151
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 152)
     pc-152
       (cl:when flag (cl:setf pc 167) (cl:go pc-167))
     pc-153
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 154)
     pc-154
       (cl:when flag (cl:setf pc 160) (cl:go pc-160))
     pc-155
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 156)
     pc-156
       (cl:when flag (cl:setf pc 165) (cl:go pc-165))
     pc-157
       (cl:setf continue (cl:cons '|assembler| 170))
       (cl:setf pc 158)
     pc-158
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 159)
     pc-159
       (cl:go zone-exit)
     pc-160
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 161)
     pc-161
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 162)
     pc-162
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 163)
     pc-163
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 164)
     pc-164
       (cl:go zone-exit)
     pc-165
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 166)
     pc-166
       (cl:setf pc 170) (cl:go pc-170)
     pc-167
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 168)
     pc-168
       (cl:setf pc 170) (cl:go pc-170)
     pc-169
       (cl:setf val cl:nil)
       (cl:setf pc 170)
     pc-170
       (cl:setf env (cl:pop stack))
       (cl:setf pc 171)
     pc-171
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 172)
     pc-172
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 173)
     pc-173
       (cl:when flag (cl:setf pc 320) (cl:go pc-320))
     pc-174
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 176 env))
       (cl:setf pc 175)
     pc-175
       (cl:setf pc 253) (cl:go pc-253)
     pc-176
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 177)
     pc-177
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|pc|) argl env 0))
       (cl:setf pc 178)
     pc-178
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 179)
     pc-179
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 180)
     pc-180
       (cl:when flag (cl:setf pc 251) (cl:go pc-251))
     pc-181
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%procedure-name-set!| env))
       (cl:setf pc 182)
     pc-182
       (cl:push continue stack)
       (cl:setf pc 183)
     pc-183
       (cl:push proc stack)
       (cl:setf pc 184)
     pc-184
       (cl:push env stack)
       (cl:setf pc 185)
     pc-185
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|caddr| env))
       (cl:setf pc 186)
     pc-186
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 187)
     pc-187
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 188)
     pc-188
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 189)
     pc-189
       (cl:when flag (cl:setf pc 204) (cl:go pc-204))
     pc-190
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 191)
     pc-191
       (cl:when flag (cl:setf pc 197) (cl:go pc-197))
     pc-192
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 193)
     pc-193
       (cl:when flag (cl:setf pc 202) (cl:go pc-202))
     pc-194
       (cl:setf continue (cl:cons '|assembler| 205))
       (cl:setf pc 195)
     pc-195
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 196)
     pc-196
       (cl:go zone-exit)
     pc-197
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 198)
     pc-198
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 199)
     pc-199
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 200)
     pc-200
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 201)
     pc-201
       (cl:go zone-exit)
     pc-202
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 203)
     pc-203
       (cl:setf pc 205) (cl:go pc-205)
     pc-204
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 205)
     pc-205
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 206)
     pc-206
       (cl:setf env (cl:pop stack))
       (cl:setf pc 207)
     pc-207
       (cl:push argl stack)
       (cl:setf pc 208)
     pc-208
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 209)
     pc-209
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 210)
     pc-210
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 211)
     pc-211
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 0 env))
       (cl:setf pc 212)
     pc-212
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 213)
     pc-213
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 214)
     pc-214
       (cl:when flag (cl:setf pc 229) (cl:go pc-229))
     pc-215
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 216)
     pc-216
       (cl:when flag (cl:setf pc 222) (cl:go pc-222))
     pc-217
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 218)
     pc-218
       (cl:when flag (cl:setf pc 227) (cl:go pc-227))
     pc-219
       (cl:setf continue (cl:cons '|assembler| 230))
       (cl:setf pc 220)
     pc-220
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 221)
     pc-221
       (cl:go zone-exit)
     pc-222
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 223)
     pc-223
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 224)
     pc-224
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 225)
     pc-225
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 226)
     pc-226
       (cl:go zone-exit)
     pc-227
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 228)
     pc-228
       (cl:setf pc 230) (cl:go pc-230)
     pc-229
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 230)
     pc-230
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 231)
     pc-231
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 232)
     pc-232
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 233)
     pc-233
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 234)
     pc-234
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 235)
     pc-235
       (cl:when flag (cl:setf pc 249) (cl:go pc-249))
     pc-236
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 237)
     pc-237
       (cl:when flag (cl:setf pc 242) (cl:go pc-242))
     pc-238
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 239)
     pc-239
       (cl:when flag (cl:setf pc 247) (cl:go pc-247))
     pc-240
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 241)
     pc-241
       (cl:go zone-exit)
     pc-242
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 243)
     pc-243
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 244)
     pc-244
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 245)
     pc-245
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 246)
     pc-246
       (cl:go zone-exit)
     pc-247
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 248)
     pc-248
       (cl:go zone-exit)
     pc-249
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 250)
     pc-250
       (cl:go zone-exit)
     pc-251
       (cl:setf val cl:nil)
       (cl:setf pc 252)
     pc-252
       (cl:go zone-exit)
     pc-253
       (cl:push continue stack)
       (cl:setf pc 254)
     pc-254
       (cl:push proc stack)
       (cl:setf pc 255)
     pc-255
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%space-label-ref| env))
       (cl:setf pc 256)
     pc-256
       (cl:push proc stack)
       (cl:setf pc 257)
     pc-257
       (cl:push env stack)
       (cl:setf pc 258)
     pc-258
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 259)
     pc-259
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 260)
     pc-260
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 261)
     pc-261
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 262)
     pc-262
       (cl:when flag (cl:setf pc 277) (cl:go pc-277))
     pc-263
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 264)
     pc-264
       (cl:when flag (cl:setf pc 270) (cl:go pc-270))
     pc-265
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 266)
     pc-266
       (cl:when flag (cl:setf pc 275) (cl:go pc-275))
     pc-267
       (cl:setf continue (cl:cons '|assembler| 278))
       (cl:setf pc 268)
     pc-268
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 269)
     pc-269
       (cl:go zone-exit)
     pc-270
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 271)
     pc-271
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 272)
     pc-272
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 273)
     pc-273
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 274)
     pc-274
       (cl:go zone-exit)
     pc-275
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 276)
     pc-276
       (cl:setf pc 278) (cl:go pc-278)
     pc-277
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 278)
     pc-278
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 279)
     pc-279
       (cl:setf env (cl:pop stack))
       (cl:setf pc 280)
     pc-280
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 281)
     pc-281
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 282)
     pc-282
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 283)
     pc-283
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 284)
     pc-284
       (cl:when flag (cl:setf pc 299) (cl:go pc-299))
     pc-285
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 286)
     pc-286
       (cl:when flag (cl:setf pc 292) (cl:go pc-292))
     pc-287
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 288)
     pc-288
       (cl:when flag (cl:setf pc 297) (cl:go pc-297))
     pc-289
       (cl:setf continue (cl:cons '|assembler| 300))
       (cl:setf pc 290)
     pc-290
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 291)
     pc-291
       (cl:go zone-exit)
     pc-292
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 293)
     pc-293
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 294)
     pc-294
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 295)
     pc-295
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 296)
     pc-296
       (cl:go zone-exit)
     pc-297
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 298)
     pc-298
       (cl:setf pc 300) (cl:go pc-300)
     pc-299
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 300)
     pc-300
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 301)
     pc-301
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 302)
     pc-302
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 303)
     pc-303
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 304)
     pc-304
       (cl:when flag (cl:setf pc 318) (cl:go pc-318))
     pc-305
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 306)
     pc-306
       (cl:when flag (cl:setf pc 311) (cl:go pc-311))
     pc-307
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 308)
     pc-308
       (cl:when flag (cl:setf pc 316) (cl:go pc-316))
     pc-309
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 310)
     pc-310
       (cl:go zone-exit)
     pc-311
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 312)
     pc-312
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 313)
     pc-313
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 314)
     pc-314
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 315)
     pc-315
       (cl:go zone-exit)
     pc-316
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 317)
     pc-317
       (cl:go zone-exit)
     pc-318
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 319)
     pc-319
       (cl:go zone-exit)
     pc-320
       (cl:push continue stack)
       (cl:setf pc 321)
     pc-321
       (cl:push env stack)
       (cl:setf pc 322)
     pc-322
       (cl:push env stack)
       (cl:setf pc 323)
     pc-323
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 324)
     pc-324
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 325)
     pc-325
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 326)
     pc-326
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 327)
     pc-327
       (cl:when flag (cl:setf pc 342) (cl:go pc-342))
     pc-328
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 329)
     pc-329
       (cl:when flag (cl:setf pc 335) (cl:go pc-335))
     pc-330
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 331)
     pc-331
       (cl:when flag (cl:setf pc 340) (cl:go pc-340))
     pc-332
       (cl:setf continue (cl:cons '|assembler| 343))
       (cl:setf pc 333)
     pc-333
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 334)
     pc-334
       (cl:go zone-exit)
     pc-335
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 336)
     pc-336
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 337)
     pc-337
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 338)
     pc-338
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 339)
     pc-339
       (cl:go zone-exit)
     pc-340
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 341)
     pc-341
       (cl:setf pc 343) (cl:go pc-343)
     pc-342
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 343)
     pc-343
       (cl:setf env (cl:pop stack))
       (cl:setf pc 344)
     pc-344
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 345)
     pc-345
       (cl:when flag (cl:setf pc 392) (cl:go pc-392))
     pc-346
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 347)
     pc-347
       (cl:push proc stack)
       (cl:setf pc 348)
     pc-348
       (cl:setf val '|source-location|)
       (cl:setf pc 349)
     pc-349
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 350)
     pc-350
       (cl:push argl stack)
       (cl:setf pc 351)
     pc-351
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 352)
     pc-352
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 353)
     pc-353
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 354)
     pc-354
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 355)
     pc-355
       (cl:when flag (cl:setf pc 370) (cl:go pc-370))
     pc-356
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 357)
     pc-357
       (cl:when flag (cl:setf pc 363) (cl:go pc-363))
     pc-358
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 359)
     pc-359
       (cl:when flag (cl:setf pc 368) (cl:go pc-368))
     pc-360
       (cl:setf continue (cl:cons '|assembler| 371))
       (cl:setf pc 361)
     pc-361
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 362)
     pc-362
       (cl:go zone-exit)
     pc-363
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 364)
     pc-364
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 365)
     pc-365
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 366)
     pc-366
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 367)
     pc-367
       (cl:go zone-exit)
     pc-368
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 369)
     pc-369
       (cl:setf pc 371) (cl:go pc-371)
     pc-370
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 371)
     pc-371
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 372)
     pc-372
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 373)
     pc-373
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 374)
     pc-374
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 375)
     pc-375
       (cl:when flag (cl:setf pc 390) (cl:go pc-390))
     pc-376
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 377)
     pc-377
       (cl:when flag (cl:setf pc 383) (cl:go pc-383))
     pc-378
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 379)
     pc-379
       (cl:when flag (cl:setf pc 388) (cl:go pc-388))
     pc-380
       (cl:setf continue (cl:cons '|assembler| 393))
       (cl:setf pc 381)
     pc-381
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 382)
     pc-382
       (cl:go zone-exit)
     pc-383
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 384)
     pc-384
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 385)
     pc-385
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 386)
     pc-386
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 387)
     pc-387
       (cl:go zone-exit)
     pc-388
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 389)
     pc-389
       (cl:setf pc 393) (cl:go pc-393)
     pc-390
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 391)
     pc-391
       (cl:setf pc 393) (cl:go pc-393)
     pc-392
       (cl:setf val cl:nil)
       (cl:setf pc 393)
     pc-393
       (cl:setf env (cl:pop stack))
       (cl:setf pc 394)
     pc-394
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 395)
     pc-395
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 396)
     pc-396
       (cl:when flag (cl:setf pc 399) (cl:go pc-399))
     pc-397
       (cl:setf val cl:nil)
       (cl:setf pc 398)
     pc-398
       (cl:go zone-exit)
     pc-399
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%space-instruction-push!| env))
       (cl:setf pc 400)
     pc-400
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 401)
     pc-401
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 402)
     pc-402
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 403)
     pc-403
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 404)
     pc-404
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 405)
     pc-405
       (cl:when flag (cl:setf pc 419) (cl:go pc-419))
     pc-406
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 407)
     pc-407
       (cl:when flag (cl:setf pc 412) (cl:go pc-412))
     pc-408
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 409)
     pc-409
       (cl:when flag (cl:setf pc 417) (cl:go pc-417))
     pc-410
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 411)
     pc-411
       (cl:go zone-exit)
     pc-412
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 413)
     pc-413
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 414)
     pc-414
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 415)
     pc-415
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 416)
     pc-416
       (cl:go zone-exit)
     pc-417
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 418)
     pc-418
       (cl:go zone-exit)
     pc-419
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 420)
     pc-420
       (cl:go zone-exit)
     pc-421
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 422)
     pc-422
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 423)
     pc-423
       (cl:when flag (cl:setf pc 438) (cl:go pc-438))
     pc-424
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 425)
     pc-425
       (cl:when flag (cl:setf pc 431) (cl:go pc-431))
     pc-426
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 427)
     pc-427
       (cl:when flag (cl:setf pc 436) (cl:go pc-436))
     pc-428
       (cl:setf continue (cl:cons '|assembler| 439))
       (cl:setf pc 429)
     pc-429
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 430)
     pc-430
       (cl:go zone-exit)
     pc-431
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 432)
     pc-432
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 433)
     pc-433
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 434)
     pc-434
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 435)
     pc-435
       (cl:go zone-exit)
     pc-436
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 437)
     pc-437
       (cl:setf pc 439) (cl:go pc-439)
     pc-438
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 439)
     pc-439
       (cl:setf env (cl:pop stack))
       (cl:setf pc 440)
     pc-440
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 441)
     pc-441
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 442)
     pc-442
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 443)
     pc-443
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 444)
     pc-444
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 445)
     pc-445
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 446)
     pc-446
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 447)
     pc-447
       (cl:when flag (cl:setf pc 461) (cl:go pc-461))
     pc-448
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 449)
     pc-449
       (cl:when flag (cl:setf pc 454) (cl:go pc-454))
     pc-450
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 451)
     pc-451
       (cl:when flag (cl:setf pc 459) (cl:go pc-459))
     pc-452
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 453)
     pc-453
       (cl:go zone-exit)
     pc-454
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 455)
     pc-455
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 456)
     pc-456
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 457)
     pc-457
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 458)
     pc-458
       (cl:go zone-exit)
     pc-459
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 460)
     pc-460
       (cl:go zone-exit)
     pc-461
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 462)
     pc-462
       (cl:go zone-exit)
     pc-463
       (cl:push continue stack)
       (cl:setf pc 464)
     pc-464
       (cl:push proc stack)
       (cl:setf pc 465)
     pc-465
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%space-instruction-length| env))
       (cl:setf pc 466)
     pc-466
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 467)
     pc-467
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 468)
     pc-468
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 469)
     pc-469
       (cl:when flag (cl:setf pc 484) (cl:go pc-484))
     pc-470
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 471)
     pc-471
       (cl:when flag (cl:setf pc 477) (cl:go pc-477))
     pc-472
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 473)
     pc-473
       (cl:when flag (cl:setf pc 482) (cl:go pc-482))
     pc-474
       (cl:setf continue (cl:cons '|assembler| 485))
       (cl:setf pc 475)
     pc-475
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 476)
     pc-476
       (cl:go zone-exit)
     pc-477
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 478)
     pc-478
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 479)
     pc-479
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 480)
     pc-480
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 481)
     pc-481
       (cl:go zone-exit)
     pc-482
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 483)
     pc-483
       (cl:setf pc 485) (cl:go pc-485)
     pc-484
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 485)
     pc-485
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 486)
     pc-486
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 487)
     pc-487
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 488)
     pc-488
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 489)
     pc-489
       (cl:when flag (cl:setf pc 503) (cl:go pc-503))
     pc-490
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 491)
     pc-491
       (cl:when flag (cl:setf pc 496) (cl:go pc-496))
     pc-492
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 493)
     pc-493
       (cl:when flag (cl:setf pc 501) (cl:go pc-501))
     pc-494
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 495)
     pc-495
       (cl:go zone-exit)
     pc-496
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 497)
     pc-497
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 498)
     pc-498
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 499)
     pc-499
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 500)
     pc-500
       (cl:go zone-exit)
     pc-501
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 502)
     pc-502
       (cl:go zone-exit)
     pc-503
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 504)
     pc-504
       (cl:go zone-exit)
     pc-505
       (cl:push continue stack)
       (cl:setf pc 506)
     pc-506
       (cl:push proc stack)
       (cl:setf pc 507)
     pc-507
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%current-space-id| env))
       (cl:setf pc 508)
     pc-508
       (cl:setf argl cl:nil)
       (cl:setf pc 509)
     pc-509
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 510)
     pc-510
       (cl:when flag (cl:setf pc 525) (cl:go pc-525))
     pc-511
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 512)
     pc-512
       (cl:when flag (cl:setf pc 518) (cl:go pc-518))
     pc-513
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 514)
     pc-514
       (cl:when flag (cl:setf pc 523) (cl:go pc-523))
     pc-515
       (cl:setf continue (cl:cons '|assembler| 526))
       (cl:setf pc 516)
     pc-516
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 517)
     pc-517
       (cl:go zone-exit)
     pc-518
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 519)
     pc-519
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 520)
     pc-520
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 521)
     pc-521
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 522)
     pc-522
       (cl:go zone-exit)
     pc-523
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 524)
     pc-524
       (cl:setf pc 526) (cl:go pc-526)
     pc-525
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 526)
     pc-526
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 527)
     pc-527
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 528)
     pc-528
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 529)
     pc-529
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 530)
     pc-530
       (cl:when flag (cl:setf pc 544) (cl:go pc-544))
     pc-531
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 532)
     pc-532
       (cl:when flag (cl:setf pc 537) (cl:go pc-537))
     pc-533
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 534)
     pc-534
       (cl:when flag (cl:setf pc 542) (cl:go pc-542))
     pc-535
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 536)
     pc-536
       (cl:go zone-exit)
     pc-537
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 538)
     pc-538
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 539)
     pc-539
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 540)
     pc-540
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 541)
     pc-541
       (cl:go zone-exit)
     pc-542
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 543)
     pc-543
       (cl:go zone-exit)
     pc-544
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 545)
     pc-545
       (cl:go zone-exit)
     pc-546
       (cl:funcall (get-operation '|define-variable!|) '|ece-assemble-into-global| val env)
       (cl:setf pc 547)
     pc-547
       (cl:setf val val)
       (cl:setf pc 548)
     pc-548
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 549)
     pc-549
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 551 env))
       (cl:setf pc 550)
     pc-550
       (cl:setf pc 956) (cl:go pc-956)
     pc-551
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 552)
     pc-552
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename|) argl env 0))
       (cl:setf pc 553)
     pc-553
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 555 env))
       (cl:setf pc 554)
     pc-554
       (cl:setf pc 914) (cl:go pc-914)
     pc-555
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 556)
     pc-556
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|port|) argl env 0))
       (cl:setf pc 557)
     pc-557
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 559 env))
       (cl:setf pc 558)
     pc-558
       (cl:setf pc 873) (cl:go pc-873)
     pc-559
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 560)
     pc-560
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|prev-space|) argl env 0))
       (cl:setf pc 561)
     pc-561
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 563 env))
       (cl:setf pc 562)
     pc-562
       (cl:setf pc 831) (cl:go pc-831)
     pc-563
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 564)
     pc-564
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|new-space|) argl env 0))
       (cl:setf pc 565)
     pc-565
       (cl:push continue stack)
       (cl:setf pc 566)
     pc-566
       (cl:push env stack)
       (cl:setf pc 567)
     pc-567
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%set-current-space-id!| env))
       (cl:setf pc 568)
     pc-568
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 569)
     pc-569
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 570)
     pc-570
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 571)
     pc-571
       (cl:when flag (cl:setf pc 586) (cl:go pc-586))
     pc-572
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 573)
     pc-573
       (cl:when flag (cl:setf pc 579) (cl:go pc-579))
     pc-574
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 575)
     pc-575
       (cl:when flag (cl:setf pc 584) (cl:go pc-584))
     pc-576
       (cl:setf continue (cl:cons '|assembler| 587))
       (cl:setf pc 577)
     pc-577
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 578)
     pc-578
       (cl:go zone-exit)
     pc-579
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 580)
     pc-580
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 581)
     pc-581
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 582)
     pc-582
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 583)
     pc-583
       (cl:go zone-exit)
     pc-584
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 585)
     pc-585
       (cl:setf pc 587) (cl:go pc-587)
     pc-586
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 587)
     pc-587
       (cl:setf env (cl:pop stack))
       (cl:setf pc 588)
     pc-588
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 589)
     pc-589
       (cl:push continue stack)
       (cl:setf pc 590)
     pc-590
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 592 env))
       (cl:setf pc 591)
     pc-591
       (cl:setf pc 790) (cl:go pc-790)
     pc-592
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 593)
     pc-593
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 594)
     pc-594
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 596 env))
       (cl:setf pc 595)
     pc-595
       (cl:setf pc 603) (cl:go pc-603)
     pc-596
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 597)
     pc-597
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g176|) argl env 0))
       (cl:setf pc 598)
     pc-598
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 599)
     pc-599
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 600)
     pc-600
       (cl:setf val val)
       (cl:setf pc 601)
     pc-601
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 602)
     pc-602
       (cl:go zone-exit)
     pc-603
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 605 env))
       (cl:setf pc 604)
     pc-604
       (cl:setf pc 772) (cl:go pc-772)
     pc-605
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 606)
     pc-606
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|result|) argl env 0))
       (cl:setf pc 607)
     pc-607
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 609 env))
       (cl:setf pc 608)
     pc-608
       (cl:setf pc 730) (cl:go pc-730)
     pc-609
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 610)
     pc-610
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|expr|) argl env 0))
       (cl:setf pc 611)
     pc-611
       (cl:push continue stack)
       (cl:setf pc 612)
     pc-612
       (cl:push env stack)
       (cl:setf pc 613)
     pc-613
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eof?| env))
       (cl:setf pc 614)
     pc-614
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 615)
     pc-615
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 616)
     pc-616
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 617)
     pc-617
       (cl:when flag (cl:setf pc 632) (cl:go pc-632))
     pc-618
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 619)
     pc-619
       (cl:when flag (cl:setf pc 625) (cl:go pc-625))
     pc-620
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 621)
     pc-621
       (cl:when flag (cl:setf pc 630) (cl:go pc-630))
     pc-622
       (cl:setf continue (cl:cons '|assembler| 633))
       (cl:setf pc 623)
     pc-623
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 624)
     pc-624
       (cl:go zone-exit)
     pc-625
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 626)
     pc-626
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 627)
     pc-627
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 628)
     pc-628
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 629)
     pc-629
       (cl:go zone-exit)
     pc-630
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 631)
     pc-631
       (cl:setf pc 633) (cl:go pc-633)
     pc-632
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 633)
     pc-633
       (cl:setf env (cl:pop stack))
       (cl:setf pc 634)
     pc-634
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 635)
     pc-635
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 636)
     pc-636
       (cl:when flag (cl:setf pc 687) (cl:go pc-687))
     pc-637
       (cl:push continue stack)
       (cl:setf pc 638)
     pc-638
       (cl:push env stack)
       (cl:setf pc 639)
     pc-639
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|close-input-port| env))
       (cl:setf pc 640)
     pc-640
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 5 0 env))
       (cl:setf pc 641)
     pc-641
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 642)
     pc-642
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 643)
     pc-643
       (cl:when flag (cl:setf pc 658) (cl:go pc-658))
     pc-644
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 645)
     pc-645
       (cl:when flag (cl:setf pc 651) (cl:go pc-651))
     pc-646
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 647)
     pc-647
       (cl:when flag (cl:setf pc 656) (cl:go pc-656))
     pc-648
       (cl:setf continue (cl:cons '|assembler| 659))
       (cl:setf pc 649)
     pc-649
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 650)
     pc-650
       (cl:go zone-exit)
     pc-651
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 652)
     pc-652
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 653)
     pc-653
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 654)
     pc-654
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 655)
     pc-655
       (cl:go zone-exit)
     pc-656
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 657)
     pc-657
       (cl:setf pc 659) (cl:go pc-659)
     pc-658
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 659)
     pc-659
       (cl:setf env (cl:pop stack))
       (cl:setf pc 660)
     pc-660
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 661)
     pc-661
       (cl:push continue stack)
       (cl:setf pc 662)
     pc-662
       (cl:push env stack)
       (cl:setf pc 663)
     pc-663
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%set-current-space-id!| env))
       (cl:setf pc 664)
     pc-664
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 4 0 env))
       (cl:setf pc 665)
     pc-665
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 666)
     pc-666
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 667)
     pc-667
       (cl:when flag (cl:setf pc 682) (cl:go pc-682))
     pc-668
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 669)
     pc-669
       (cl:when flag (cl:setf pc 675) (cl:go pc-675))
     pc-670
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 671)
     pc-671
       (cl:when flag (cl:setf pc 680) (cl:go pc-680))
     pc-672
       (cl:setf continue (cl:cons '|assembler| 683))
       (cl:setf pc 673)
     pc-673
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 674)
     pc-674
       (cl:go zone-exit)
     pc-675
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 676)
     pc-676
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 677)
     pc-677
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 678)
     pc-678
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 679)
     pc-679
       (cl:go zone-exit)
     pc-680
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 681)
     pc-681
       (cl:setf pc 683) (cl:go pc-683)
     pc-682
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 683)
     pc-683
       (cl:setf env (cl:pop stack))
       (cl:setf pc 684)
     pc-684
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 685)
     pc-685
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 686)
     pc-686
       (cl:go zone-exit)
     pc-687
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 688)
     pc-688
       (cl:push continue stack)
       (cl:setf pc 689)
     pc-689
       (cl:push proc stack)
       (cl:setf pc 690)
     pc-690
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|mc-compile-and-go| env))
       (cl:setf pc 691)
     pc-691
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 692)
     pc-692
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 693)
     pc-693
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 694)
     pc-694
       (cl:when flag (cl:setf pc 709) (cl:go pc-709))
     pc-695
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 696)
     pc-696
       (cl:when flag (cl:setf pc 702) (cl:go pc-702))
     pc-697
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 698)
     pc-698
       (cl:when flag (cl:setf pc 707) (cl:go pc-707))
     pc-699
       (cl:setf continue (cl:cons '|assembler| 710))
       (cl:setf pc 700)
     pc-700
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 701)
     pc-701
       (cl:go zone-exit)
     pc-702
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 703)
     pc-703
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 704)
     pc-704
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 705)
     pc-705
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 706)
     pc-706
       (cl:go zone-exit)
     pc-707
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 708)
     pc-708
       (cl:setf pc 710) (cl:go pc-710)
     pc-709
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 710)
     pc-710
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 711)
     pc-711
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 712)
     pc-712
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 713)
     pc-713
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 714)
     pc-714
       (cl:when flag (cl:setf pc 728) (cl:go pc-728))
     pc-715
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 716)
     pc-716
       (cl:when flag (cl:setf pc 721) (cl:go pc-721))
     pc-717
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 718)
     pc-718
       (cl:when flag (cl:setf pc 726) (cl:go pc-726))
     pc-719
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 720)
     pc-720
       (cl:go zone-exit)
     pc-721
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 722)
     pc-722
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 723)
     pc-723
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 724)
     pc-724
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 725)
     pc-725
       (cl:go zone-exit)
     pc-726
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 727)
     pc-727
       (cl:go zone-exit)
     pc-728
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 729)
     pc-729
       (cl:go zone-exit)
     pc-730
       (cl:push continue stack)
       (cl:setf pc 731)
     pc-731
       (cl:push proc stack)
       (cl:setf pc 732)
     pc-732
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|ece-scheme-read| env))
       (cl:setf pc 733)
     pc-733
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 4 0 env))
       (cl:setf pc 734)
     pc-734
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 735)
     pc-735
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 736)
     pc-736
       (cl:when flag (cl:setf pc 751) (cl:go pc-751))
     pc-737
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 738)
     pc-738
       (cl:when flag (cl:setf pc 744) (cl:go pc-744))
     pc-739
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 740)
     pc-740
       (cl:when flag (cl:setf pc 749) (cl:go pc-749))
     pc-741
       (cl:setf continue (cl:cons '|assembler| 752))
       (cl:setf pc 742)
     pc-742
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 743)
     pc-743
       (cl:go zone-exit)
     pc-744
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 745)
     pc-745
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 746)
     pc-746
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 747)
     pc-747
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 748)
     pc-748
       (cl:go zone-exit)
     pc-749
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 750)
     pc-750
       (cl:setf pc 752) (cl:go pc-752)
     pc-751
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 752)
     pc-752
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 753)
     pc-753
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 754)
     pc-754
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 755)
     pc-755
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 756)
     pc-756
       (cl:when flag (cl:setf pc 770) (cl:go pc-770))
     pc-757
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 758)
     pc-758
       (cl:when flag (cl:setf pc 763) (cl:go pc-763))
     pc-759
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 760)
     pc-760
       (cl:when flag (cl:setf pc 768) (cl:go pc-768))
     pc-761
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 762)
     pc-762
       (cl:go zone-exit)
     pc-763
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 764)
     pc-764
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 765)
     pc-765
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 766)
     pc-766
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 767)
     pc-767
       (cl:go zone-exit)
     pc-768
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 769)
     pc-769
       (cl:go zone-exit)
     pc-770
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 771)
     pc-771
       (cl:go zone-exit)
     pc-772
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 773)
     pc-773
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 774)
     pc-774
       (cl:when flag (cl:setf pc 788) (cl:go pc-788))
     pc-775
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 776)
     pc-776
       (cl:when flag (cl:setf pc 781) (cl:go pc-781))
     pc-777
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 778)
     pc-778
       (cl:when flag (cl:setf pc 786) (cl:go pc-786))
     pc-779
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 780)
     pc-780
       (cl:go zone-exit)
     pc-781
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 782)
     pc-782
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 783)
     pc-783
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 784)
     pc-784
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 785)
     pc-785
       (cl:go zone-exit)
     pc-786
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 787)
     pc-787
       (cl:go zone-exit)
     pc-788
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 789)
     pc-789
       (cl:go zone-exit)
     pc-790
       (cl:setf val cl:nil)
       (cl:setf pc 791)
     pc-791
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 792)
     pc-792
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 793)
     pc-793
       (cl:when flag (cl:setf pc 810) (cl:go pc-810))
     pc-794
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 795)
     pc-795
       (cl:when flag (cl:setf pc 803) (cl:go pc-803))
     pc-796
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 797)
     pc-797
       (cl:when flag (cl:setf pc 808) (cl:go pc-808))
     pc-798
       (cl:setf continue (cl:cons '|assembler| 801))
       (cl:setf pc 799)
     pc-799
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 800)
     pc-800
       (cl:go zone-exit)
     pc-801
       (cl:setf proc val)
       (cl:setf pc 802)
     pc-802
       (cl:setf pc 811) (cl:go pc-811)
     pc-803
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 804)
     pc-804
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 805)
     pc-805
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 806)
     pc-806
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 807)
     pc-807
       (cl:go zone-exit)
     pc-808
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 809)
     pc-809
       (cl:setf pc 811) (cl:go pc-811)
     pc-810
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 811)
     pc-811
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 812)
     pc-812
       (cl:setf val cl:nil)
       (cl:setf pc 813)
     pc-813
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 814)
     pc-814
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 815)
     pc-815
       (cl:when flag (cl:setf pc 829) (cl:go pc-829))
     pc-816
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 817)
     pc-817
       (cl:when flag (cl:setf pc 822) (cl:go pc-822))
     pc-818
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 819)
     pc-819
       (cl:when flag (cl:setf pc 827) (cl:go pc-827))
     pc-820
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 821)
     pc-821
       (cl:go zone-exit)
     pc-822
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 823)
     pc-823
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 824)
     pc-824
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 825)
     pc-825
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 826)
     pc-826
       (cl:go zone-exit)
     pc-827
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 828)
     pc-828
       (cl:go zone-exit)
     pc-829
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 830)
     pc-830
       (cl:go zone-exit)
     pc-831
       (cl:push continue stack)
       (cl:setf pc 832)
     pc-832
       (cl:push proc stack)
       (cl:setf pc 833)
     pc-833
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%create-space| env))
       (cl:setf pc 834)
     pc-834
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 835)
     pc-835
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 836)
     pc-836
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 837)
     pc-837
       (cl:when flag (cl:setf pc 852) (cl:go pc-852))
     pc-838
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 839)
     pc-839
       (cl:when flag (cl:setf pc 845) (cl:go pc-845))
     pc-840
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 841)
     pc-841
       (cl:when flag (cl:setf pc 850) (cl:go pc-850))
     pc-842
       (cl:setf continue (cl:cons '|assembler| 853))
       (cl:setf pc 843)
     pc-843
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 844)
     pc-844
       (cl:go zone-exit)
     pc-845
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 846)
     pc-846
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 847)
     pc-847
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 848)
     pc-848
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 849)
     pc-849
       (cl:go zone-exit)
     pc-850
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 851)
     pc-851
       (cl:setf pc 853) (cl:go pc-853)
     pc-852
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 853)
     pc-853
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 854)
     pc-854
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 855)
     pc-855
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 856)
     pc-856
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 857)
     pc-857
       (cl:when flag (cl:setf pc 871) (cl:go pc-871))
     pc-858
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 859)
     pc-859
       (cl:when flag (cl:setf pc 864) (cl:go pc-864))
     pc-860
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 861)
     pc-861
       (cl:when flag (cl:setf pc 869) (cl:go pc-869))
     pc-862
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 863)
     pc-863
       (cl:go zone-exit)
     pc-864
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 865)
     pc-865
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 866)
     pc-866
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 867)
     pc-867
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 868)
     pc-868
       (cl:go zone-exit)
     pc-869
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 870)
     pc-870
       (cl:go zone-exit)
     pc-871
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 872)
     pc-872
       (cl:go zone-exit)
     pc-873
       (cl:push continue stack)
       (cl:setf pc 874)
     pc-874
       (cl:push proc stack)
       (cl:setf pc 875)
     pc-875
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%current-space-id| env))
       (cl:setf pc 876)
     pc-876
       (cl:setf argl cl:nil)
       (cl:setf pc 877)
     pc-877
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 878)
     pc-878
       (cl:when flag (cl:setf pc 893) (cl:go pc-893))
     pc-879
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 880)
     pc-880
       (cl:when flag (cl:setf pc 886) (cl:go pc-886))
     pc-881
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 882)
     pc-882
       (cl:when flag (cl:setf pc 891) (cl:go pc-891))
     pc-883
       (cl:setf continue (cl:cons '|assembler| 894))
       (cl:setf pc 884)
     pc-884
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 885)
     pc-885
       (cl:go zone-exit)
     pc-886
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 887)
     pc-887
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 888)
     pc-888
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 889)
     pc-889
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 890)
     pc-890
       (cl:go zone-exit)
     pc-891
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 892)
     pc-892
       (cl:setf pc 894) (cl:go pc-894)
     pc-893
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 894)
     pc-894
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 895)
     pc-895
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 896)
     pc-896
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 897)
     pc-897
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 898)
     pc-898
       (cl:when flag (cl:setf pc 912) (cl:go pc-912))
     pc-899
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 900)
     pc-900
       (cl:when flag (cl:setf pc 905) (cl:go pc-905))
     pc-901
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 902)
     pc-902
       (cl:when flag (cl:setf pc 910) (cl:go pc-910))
     pc-903
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 904)
     pc-904
       (cl:go zone-exit)
     pc-905
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 906)
     pc-906
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 907)
     pc-907
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 908)
     pc-908
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 909)
     pc-909
       (cl:go zone-exit)
     pc-910
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 911)
     pc-911
       (cl:go zone-exit)
     pc-912
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 913)
     pc-913
       (cl:go zone-exit)
     pc-914
       (cl:push continue stack)
       (cl:setf pc 915)
     pc-915
       (cl:push proc stack)
       (cl:setf pc 916)
     pc-916
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|open-input-file| env))
       (cl:setf pc 917)
     pc-917
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 918)
     pc-918
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 919)
     pc-919
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 920)
     pc-920
       (cl:when flag (cl:setf pc 935) (cl:go pc-935))
     pc-921
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 922)
     pc-922
       (cl:when flag (cl:setf pc 928) (cl:go pc-928))
     pc-923
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 924)
     pc-924
       (cl:when flag (cl:setf pc 933) (cl:go pc-933))
     pc-925
       (cl:setf continue (cl:cons '|assembler| 936))
       (cl:setf pc 926)
     pc-926
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 927)
     pc-927
       (cl:go zone-exit)
     pc-928
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 929)
     pc-929
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 930)
     pc-930
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 931)
     pc-931
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 932)
     pc-932
       (cl:go zone-exit)
     pc-933
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 934)
     pc-934
       (cl:setf pc 936) (cl:go pc-936)
     pc-935
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 936)
     pc-936
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 937)
     pc-937
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 938)
     pc-938
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 939)
     pc-939
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 940)
     pc-940
       (cl:when flag (cl:setf pc 954) (cl:go pc-954))
     pc-941
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 942)
     pc-942
       (cl:when flag (cl:setf pc 947) (cl:go pc-947))
     pc-943
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 944)
     pc-944
       (cl:when flag (cl:setf pc 952) (cl:go pc-952))
     pc-945
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 946)
     pc-946
       (cl:go zone-exit)
     pc-947
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 948)
     pc-948
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 949)
     pc-949
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 950)
     pc-950
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 951)
     pc-951
       (cl:go zone-exit)
     pc-952
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 953)
     pc-953
       (cl:go zone-exit)
     pc-954
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 955)
     pc-955
       (cl:go zone-exit)
     pc-956
       (cl:funcall (get-operation '|define-variable!|) '|load| val env)
       (cl:setf pc 957)
     pc-957
       (cl:setf val val)
       (cl:setf pc 958)
     pc-958
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 959)
     pc-959
       (cl:setf val (cl:funcall (get-operation '|lookup-variable-value|) '|ece-assemble-into-global| env))
       (cl:setf pc 960)
     pc-960
       (cl:funcall (get-operation '|define-variable!|) '|assemble-into-global| val env)
       (cl:setf pc 961)
     pc-961
       (cl:setf val val)
       (cl:setf pc 962)
     zone-exit)
    (cl:values pc val env proc argl continue stack)))

;;; Self-registration: install zone-assembler under the space symbol so
;;; execute-instructions dispatches to it on entry to this space.
(cl:setf (cl:gethash '|assembler| *compiled-zone-functions*)
         (cl:function zone-assembler))
