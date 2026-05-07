import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UserProvider _userProvider = Get.find<UserProvider>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Login type: 0 = phone, 1 = email
  final RxInt loginType = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final controller = loginType.value == 0 ? _phoneController : _emailController;

    if (controller.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入账号和密码');
      return;
    }

    isLoading.value = true;

    bool success;
    if (loginType.value == 0) {
      success = await _userProvider.loginWithPhone(
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      success = await _userProvider.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    isLoading.value = false;

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                '欢迎回来',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '登录Music以继续',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),

              const SizedBox(height: 48),

              // Login Type Selector
              Obx(() => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _LoginTypeButton(
                        label: '手机号登录',
                        isSelected: loginType.value == 0,
                        onTap: () => loginType.value = 0,
                      ),
                    ),
                    Expanded(
                      child: _LoginTypeButton(
                        label: '邮箱登录',
                        isSelected: loginType.value == 1,
                        onTap: () => loginType.value = 1,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 24),

              // Phone/Email Input
              Obx(() {
                if (loginType.value == 0) {
                  return TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '请输入手机号',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  );
                } else {
                  return TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: '请输入邮箱',
                      prefixIcon: Icon(Icons.email),
                    ),
                  );
                }
              }),

              const SizedBox(height: 16),

              // Password Input
              Obx(() => TextField(
                controller: _passwordController,
                obscureText: obscurePassword.value,
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => obscurePassword.value = !obscurePassword.value,
                  ),
                ),
              )),

              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    '忘记密码？',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Button
              Obx(() => ElevatedButton(
                onPressed: isLoading.value ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('登录'),
              )),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '其他登录方式',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // Social Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialLoginButton(
                    icon: Icons.message,
                    label: '微信',
                    color: const Color(0xFF07C160),
                    onTap: () {},
                  ),
                  const SizedBox(width: 32),
                  _SocialLoginButton(
                    icon: Icons.chat,
                    label: 'QQ',
                    color: const Color(0xFF12B7F5),
                    onTap: () {},
                  ),
                  const SizedBox(width: 32),
                  _SocialLoginButton(
                    icon: Icons.alternate_email,
                    label: '微博',
                    color: const Color(0xFFE6162D),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '还没有账号？',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('立即注册'),
                  ),
                ],
              ),

              // Terms
              Text(
                '登录即表示同意《用户协议》和《隐私政策》',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
