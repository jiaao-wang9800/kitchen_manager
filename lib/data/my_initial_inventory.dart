// lib/data/my_initial_inventory.dart
import '../models/app_models.dart';

// 🌟 你的专属初始厨房库存（包含严谨的膳食分类 Dietary Group）
List<Ingredient> myInitialInventory = [
  
  // ==========================================
  // ❄️ 冷藏区 (Fridge)
  // ==========================================
  // cat_f1: 鲜肉
  Ingredient(id: 'inv_f1_1', name: '鸡翅', categoryId: 'cat_f1', inStock: true, caloriesPer100g: 200.0, proteinPer100g: 18.0, carbsPer100g: 0.0, fatPer100g: 15.0, nutritionalTags: ['高蛋白', '白肉'], 
    dietaryGroup: DietaryGroup.meatAndPoultry, dietarySubGroup: '禽肉'),
  
  // cat_f2: 鸡蛋&乳制品
  Ingredient(id: 'inv_f2_1', name: '鸡蛋', categoryId: 'cat_f2', inStock: true, caloriesPer100g: 143.0, proteinPer100g: 13.0, carbsPer100g: 1.0, fatPer100g: 10.0, nutritionalTags: ['优质蛋白', '必需氨基酸'], 
    dietaryGroup: DietaryGroup.eggs, dietarySubGroup: '鸡蛋'),
  Ingredient(id: 'inv_f2_2', name: '牛奶', categoryId: 'cat_f2', inStock: true, caloriesPer100g: 54.0, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.2, nutritionalTags: ['补钙', '高蛋白'], 
    dietaryGroup: DietaryGroup.dairy, dietarySubGroup: '液态奶'),

  // cat_f3: 蔬菜
  Ingredient(id: 'inv_f3_1', name: '菜心', categoryId: 'cat_f3', inStock: true, caloriesPer100g: 20.0, proteinPer100g: 1.5, carbsPer100g: 3.0, fatPer100g: 0.2, nutritionalTags: ['富含维生素', '高膳食纤维'], 
    dietaryGroup: DietaryGroup.vegetables, dietarySubGroup: '深色蔬菜'),
  Ingredient(id: 'inv_f3_2', name: '卷心菜', categoryId: 'cat_f3', inStock: true, caloriesPer100g: 25.0, proteinPer100g: 1.3, carbsPer100g: 5.0, fatPer100g: 0.2, nutritionalTags: ['维生素C', '低热量'], 
    dietaryGroup: DietaryGroup.vegetables, dietarySubGroup: '浅色蔬菜'),
  Ingredient(id: 'inv_f3_3', name: '白菜', categoryId: 'cat_f3', inStock: true, caloriesPer100g: 16.0, proteinPer100g: 1.5, carbsPer100g: 3.0, fatPer100g: 0.1, nutritionalTags: ['低热量', '水分足'], 
    dietaryGroup: DietaryGroup.vegetables, dietarySubGroup: '浅色蔬菜'),

  // cat_f4: 葱姜蒜
  Ingredient(id: 'inv_f4_1', name: '葱', categoryId: 'cat_f4', inStock: true, caloriesPer100g: 30.0, proteinPer100g: 1.5, carbsPer100g: 5.0, fatPer100g: 0.3, nutritionalTags: ['去腥', '提香'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '葱姜蒜'),
  Ingredient(id: 'inv_f4_2', name: '姜', categoryId: 'cat_f4', inStock: true, caloriesPer100g: 80.0, proteinPer100g: 1.8, carbsPer100g: 17.0, fatPer100g: 0.7, nutritionalTags: ['驱寒', '去腥'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '葱姜蒜'),
  Ingredient(id: 'inv_f4_3', name: '蒜', categoryId: 'cat_f4', inStock: true, caloriesPer100g: 149.0, proteinPer100g: 6.3, carbsPer100g: 33.0, fatPer100g: 0.5, nutritionalTags: ['杀菌', '提香'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '葱姜蒜'),

  // ==========================================
  // 🧊 冷冻区 (Freezer)
  // ==========================================
  // cat_fz1: 快手早餐
  Ingredient(id: 'inv_fz1_1', name: '手抓饼', categoryId: 'cat_fz1', inStock: true, caloriesPer100g: 300.0, proteinPer100g: 5.0, carbsPer100g: 40.0, fatPer100g: 15.0, nutritionalTags: ['高碳水', '便捷'], 
    dietaryGroup: DietaryGroup.grains, dietarySubGroup: '面食加工品'),

  // cat_fz2: 丸子
  Ingredient(id: 'inv_fz2_1', name: '鱼饼', categoryId: 'cat_fz2', inStock: true, caloriesPer100g: 110.0, proteinPer100g: 12.0, carbsPer100g: 10.0, fatPer100g: 2.0, nutritionalTags: ['高蛋白', '低脂'], 
    dietaryGroup: DietaryGroup.seafood, dietarySubGroup: '水产制品'),
  Ingredient(id: 'inv_fz2_2', name: '牛筋丸', categoryId: 'cat_fz2', inStock: true, caloriesPer100g: 250.0, proteinPer100g: 16.0, carbsPer100g: 5.0, fatPer100g: 18.0, nutritionalTags: ['劲道', '高蛋白'], 
    dietaryGroup: DietaryGroup.meatAndPoultry, dietarySubGroup: '肉制品'),

  // cat_fz3: 海鲜
  Ingredient(id: 'inv_fz3_1', name: '鱿鱼花', categoryId: 'cat_fz3', inStock: true, caloriesPer100g: 75.0, proteinPer100g: 16.0, carbsPer100g: 0.0, fatPer100g: 1.0, nutritionalTags: ['低脂', '高蛋白'], 
    dietaryGroup: DietaryGroup.seafood, dietarySubGroup: '软体动物'),
  Ingredient(id: 'inv_fz3_2', name: '虾仁', categoryId: 'cat_fz3', inStock: true, caloriesPer100g: 85.0, proteinPer100g: 20.0, carbsPer100g: 0.0, fatPer100g: 0.5, nutritionalTags: ['极低脂', '高蛋白'], 
    dietaryGroup: DietaryGroup.seafood, dietarySubGroup: '甲壳类'),

  // cat_fz4: 冻肉
  Ingredient(id: 'inv_fz4_1', name: '牛肋条', categoryId: 'cat_fz4', inStock: true, caloriesPer100g: 350.0, proteinPer100g: 15.0, carbsPer100g: 0.0, fatPer100g: 30.0, nutritionalTags: ['高脂肪', '红肉'], 
    dietaryGroup: DietaryGroup.meatAndPoultry, dietarySubGroup: '畜肉'),
  Ingredient(id: 'inv_fz4_2', name: '排骨', categoryId: 'cat_fz4', inStock: true, caloriesPer100g: 270.0, proteinPer100g: 15.0, carbsPer100g: 0.0, fatPer100g: 23.0, nutritionalTags: ['富含铁', '红肉'], 
    dietaryGroup: DietaryGroup.meatAndPoultry, dietarySubGroup: '畜肉'),

  // ==========================================
  // 🚪 橱柜区 (Cupboard)
  // ==========================================
  // cat_c1: 米
  Ingredient(id: 'inv_c1_1', name: '大米', categoryId: 'cat_c1', inStock: true, caloriesPer100g: 345.0, proteinPer100g: 7.0, carbsPer100g: 78.0, fatPer100g: 1.0, nutritionalTags: ['主食', '高碳水'], 
    dietaryGroup: DietaryGroup.grains, dietarySubGroup: '精制谷物'),
  
  // cat_c2: 面
  Ingredient(id: 'inv_c2_1', name: '刀削面', categoryId: 'cat_c2', inStock: true, caloriesPer100g: 350.0, proteinPer100g: 10.0, carbsPer100g: 74.0, fatPer100g: 1.5, nutritionalTags: ['面食', '饱腹感'], 
    dietaryGroup: DietaryGroup.grains, dietarySubGroup: '面制品'),
  Ingredient(id: 'inv_c2_2', name: '挂面', categoryId: 'cat_c2', inStock: true, caloriesPer100g: 350.0, proteinPer100g: 10.0, carbsPer100g: 75.0, fatPer100g: 1.5, nutritionalTags: ['面食', '易储存'], 
    dietaryGroup: DietaryGroup.grains, dietarySubGroup: '面制品'),

  // cat_c3: 粉
  Ingredient(id: 'inv_c3_1', name: '粉丝', categoryId: 'cat_c3', inStock: true, caloriesPer100g: 340.0, proteinPer100g: 0.2, carbsPer100g: 84.0, fatPer100g: 0.2, nutritionalTags: ['纯碳水', '吸汁'], 
    dietaryGroup: DietaryGroup.grains, dietarySubGroup: '淀粉制品'),

  // cat_c4: 粗粮
  Ingredient(id: 'inv_c4_1', name: '南瓜', categoryId: 'cat_c4', inStock: true, caloriesPer100g: 26.0, proteinPer100g: 1.0, carbsPer100g: 6.0, fatPer100g: 0.1, nutritionalTags: ['低热量', '高膳食纤维'], 
    dietaryGroup: DietaryGroup.vegetables, dietarySubGroup: '瓜类蔬菜'),
  Ingredient(id: 'inv_c4_2', name: '玉米', categoryId: 'cat_c4', inStock: true, caloriesPer100g: 86.0, proteinPer100g: 3.2, carbsPer100g: 19.0, fatPer100g: 1.2, nutritionalTags: ['粗粮', '饱腹感'], 
    dietaryGroup: DietaryGroup.grains, dietarySubGroup: '全谷物'),

  // cat_c6: 干货
  Ingredient(id: 'inv_c6_1', name: '红枣', categoryId: 'cat_c6', inStock: true, caloriesPer100g: 264.0, proteinPer100g: 3.0, carbsPer100g: 67.0, fatPer100g: 0.5, nutritionalTags: ['补气血', '高糖'], 
    dietaryGroup: DietaryGroup.fruits, dietarySubGroup: '干果'),

  // cat_c7: 罐头
  Ingredient(id: 'inv_c7_1', name: '番茄罐头', categoryId: 'cat_c7', inStock: true, caloriesPer100g: 32.0, proteinPer100g: 1.0, carbsPer100g: 7.0, fatPer100g: 0.0, nutritionalTags: ['番茄红素', '百搭'], 
    dietaryGroup: DietaryGroup.vegetables, dietarySubGroup: '蔬菜制品'),

  // ==========================================
  // 🧂 调料区 (Spices)
  // ==========================================
  // cat_s1: 香料
  Ingredient(id: 'inv_s1_1', name: '八角', categoryId: 'cat_s1', inStock: true, caloriesPer100g: 337.0, proteinPer100g: 15.0, carbsPer100g: 50.0, fatPer100g: 15.0, nutritionalTags: ['香料', '提鲜'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '香辛料'),
  Ingredient(id: 'inv_s1_2', name: '桂皮', categoryId: 'cat_s1', inStock: true, caloriesPer100g: 247.0, proteinPer100g: 4.0, carbsPer100g: 80.0, fatPer100g: 1.0, nutritionalTags: ['香料', '去腥'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '香辛料'),
  Ingredient(id: 'inv_s1_3', name: '香叶', categoryId: 'cat_s1', inStock: true, caloriesPer100g: 313.0, proteinPer100g: 7.0, carbsPer100g: 75.0, fatPer100g: 8.0, nutritionalTags: ['香料', '提香'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '香辛料'),
  Ingredient(id: 'inv_s1_4', name: '白芷', categoryId: 'cat_s1', inStock: true, caloriesPer100g: 300.0, proteinPer100g: 10.0, carbsPer100g: 60.0, fatPer100g: 5.0, nutritionalTags: ['药食同源', '去腥'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '香辛料'),
  Ingredient(id: 'inv_s1_5', name: '干辣椒', categoryId: 'cat_s1', inStock: true, caloriesPer100g: 324.0, proteinPer100g: 15.0, carbsPer100g: 55.0, fatPer100g: 10.0, nutritionalTags: ['辛辣', '提味'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '香辛料'),

  // cat_s2: 食用油
  Ingredient(id: 'inv_s2_1', name: '菜籽油', categoryId: 'cat_s2', inStock: true, caloriesPer100g: 899.0, proteinPer100g: 0.0, carbsPer100g: 0.0, fatPer100g: 99.9, nutritionalTags: ['纯脂肪', '不饱和脂肪酸'], 
    dietaryGroup: DietaryGroup.oils, dietarySubGroup: '植物油'),

  // cat_s3: 基础调味料
  Ingredient(id: 'inv_s3_1', name: '盐', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 0.0, proteinPer100g: 0.0, carbsPer100g: 0.0, fatPer100g: 0.0, nutritionalTags: ['基础调味', '钠元素'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_2', name: '糖', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 400.0, proteinPer100g: 0.0, carbsPer100g: 100.0, fatPer100g: 0.0, nutritionalTags: ['纯碳水', '提鲜'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_3', name: '生抽', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 50.0, proteinPer100g: 5.0, carbsPer100g: 5.0, fatPer100g: 0.0, nutritionalTags: ['提鲜', '含钠'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_4', name: '老抽', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 60.0, proteinPer100g: 5.0, carbsPer100g: 10.0, fatPer100g: 0.0, nutritionalTags: ['上色', '含钠'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_5', name: '蚝油', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 115.0, proteinPer100g: 5.0, carbsPer100g: 20.0, fatPer100g: 0.0, nutritionalTags: ['提鲜', '复合调味'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_6', name: '红油', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 850.0, proteinPer100g: 1.0, carbsPer100g: 5.0, fatPer100g: 90.0, nutritionalTags: ['高脂', '香辣'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_7', name: '黄冰糖', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 398.0, proteinPer100g: 0.0, carbsPer100g: 99.0, fatPer100g: 0.0, nutritionalTags: ['纯碳水', '炖煮上色'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),
  Ingredient(id: 'inv_s3_8', name: '泡椒', categoryId: 'cat_s3', inStock: true, caloriesPer100g: 25.0, proteinPer100g: 1.0, carbsPer100g: 5.0, fatPer100g: 0.1, nutritionalTags: ['发酵', '酸辣'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '调味料'),

  // cat_s4: 复合调味包
  Ingredient(id: 'inv_s4_1', name: '火锅底料', categoryId: 'cat_s4', inStock: true, caloriesPer100g: 600.0, proteinPer100g: 5.0, carbsPer100g: 15.0, fatPer100g: 60.0, nutritionalTags: ['高脂', '重油重盐'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '复合调味'),
  Ingredient(id: 'inv_s4_2', name: '麻辣香锅底料', categoryId: 'cat_s4', inStock: true, caloriesPer100g: 500.0, proteinPer100g: 6.0, carbsPer100g: 20.0, fatPer100g: 50.0, nutritionalTags: ['高脂', '复合调味'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '复合调味'),
  Ingredient(id: 'inv_s4_3', name: '火锅蘸料', categoryId: 'cat_s4', inStock: true, caloriesPer100g: 300.0, proteinPer100g: 8.0, carbsPer100g: 20.0, fatPer100g: 20.0, nutritionalTags: ['复合调味', '提味'], 
    dietaryGroup: DietaryGroup.saltAndCondiments, dietarySubGroup: '复合调味'),

  // ==========================================
  // ☕ 茶水间 (Pantry)
  // ==========================================
  // cat_p4: 甜品
  Ingredient(id: 'inv_p4_1', name: '柿饼', categoryId: 'cat_p4', inStock: true, caloriesPer100g: 250.0, proteinPer100g: 1.5, carbsPer100g: 62.0, fatPer100g: 0.5, nutritionalTags: ['高糖', '风味零食'], 
    dietaryGroup: DietaryGroup.fruits, dietarySubGroup: '干果'),

];