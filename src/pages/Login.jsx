import { useForm } from "react-hook-form";
import { useMutation } from "@tanstack/react-query"
import { useAuthContext } from '../context/AuthContext'
import { useNavigate } from "react-router-dom";
import * as z from "zod";
import { zodResolver } from '@hookform/resolvers/zod';
import config from '../config';

const loginSchema = z.object({
  email: z.email({ pattern: z.regexes.html5Email }),
  password: z.string().regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    { error: "Password must be 8+ characters with uppercase, lowercase, number, and special character." }
  )
});

const Login = () => {

  const { setToken, setUser } = useAuthContext();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting, isDirty }
  } = useForm({
    defaultValues: {
      email: '',
      password: '',
    },
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = (data) => {
    loginMutation.mutate(data);
  };

  const loginMutation = useMutation({
    mutationFn: async (data) => {
      const response = await fetch(`${config.API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });

      // //  Unsuccessful
      if (!response.ok) throw new Error()
      // // Successful
      return await response.json()
    },
    // data here is response from mutationFn
    onSuccess: (data) => {
      console.log(data)
      setUser({ email: data.email, id: data._id })
      // store jwt in context
      setToken(data.access_token)
      // navigate somewhere else after successful login, e.g. home page
      navigate(-1)  // Navigate back to previous page after login
    },
    // errorResponse is from above
    onError: () => {
      setError("root", {
        message: "Error logging in. Please check your credentials and try again.",
      });
    }
  })

  return (
    <div className="max-w-md mx-auto my-8 p-8 bg-zinc-900 rounded-lg border border-zinc-800 shadow-lg">
      <h2 className="text-center mb-6 text-2xl font-bold text-white">Login</h2>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="mb-4">
          <label htmlFor="email" className="block mb-1 text-zinc-300">Email</label>
          <input
            {...register('email')}
            id="email"
            type="text"
            className="w-full px-3 py-2 rounded border border-zinc-700 bg-zinc-800 text-white focus:outline-none focus:border-red-700"
            autoComplete="email"
          />
          {errors.email && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.email.message}</span>}
        </div>
        <div style={{ marginBottom: '1.5rem' }}>
          <label htmlFor="password" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>Password</label>
          <input
            {...register('password')}
            id="password"
            type="password"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="current-password"
          />
          {errors.password && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.password.message}</span>}
        </div>
        <button disabled={!isDirty} type="submit" className="w-full py-2.5 bg-[#e50914] text-white border-none rounded font-bold text-lg cursor-pointer disabled:bg-[#333] disabled:text-[#666] disabled:cursor-not-allowed">
          {isSubmitting ? "Logging in..." : "Submit"}
        </button>
        {errors.root && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.root.message}</span>}
      </form>
    </div>
  );
};

export default Login;
