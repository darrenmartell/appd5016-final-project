import { useForm } from "react-hook-form";
import { useMutation } from "@tanstack/react-query"
import { useAuthContext } from '../context/AuthContext'
import { useNavigate } from "react-router-dom";
import * as z from "zod";
import { zodResolver } from '@hookform/resolvers/zod';
import config from '../config';

const registerSchema = z.object({
  firstName: z.string().min(1, { message: "First Name required" }),
  lastName: z.string().min(1, { message: "Last Name required" }),
  email: z.email({ pattern: z.regexes.html5Email }),
  password: z.string().regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    { error: "Password must be 8+ characters with uppercase, lowercase, number, and special character." }
  ),
  confirmPassword: z.string().regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    { error: "Password must be 8+ characters with uppercase, lowercase, number, and special character." }
  )
});

const Register = () => {
  const { setToken, setUser } = useAuthContext();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    watch,
    setError,
    formState: { errors, isSubmitting, isDirty }
  } = useForm({
    defaultValues: {
      firstName: '',
      lastName: '',
      email: '',
      password: '',
      confirmPassword: '',
    },
    resolver: zodResolver(registerSchema),
  });

  const onSubmit = (data) => {
    const { confirmPassword, ...dataToSubmit } = data;  // removes confirmPassord from the data to submit
    registerMutation.mutate(dataToSubmit);
  };

  const registerMutation = useMutation({
    mutationFn: async (data) => {
      const response = await fetch(`${config.API_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });

      //  Unsuccessful
      if (!response.ok) throw new Error(response)
      // Successful
      return await response.json()
    },
    // data here is response from mutationFn
    onSuccess: (data) => {
      // Sets the user in context
      setUser({ email: data.email, id: data._id })
      // store jwt in context
      setToken(data.accessToken)
      // navigate somewhere else after successful registration
      navigate('/admin/home')
    },
    // errorResponse is from above
    onError: () => {
      setError("root", {
        message: "Error registering. Please check your credentials and try again.",
      });
      // Clear user context on registration failure 
      setUser(null)
    }
  })

  // eslint-disable-next-line react-hooks/incompatible-library
  const password = watch('password', ''); // Watch password field for confirm password validation

  return (
    <div className="max-w-md mx-auto my-8 p-8 bg-zinc-900 rounded-lg border border-zinc-800 shadow-lg">
      <h2 className="text-center mb-6 text-2xl font-bold text-white">Register</h2>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="mb-4">
          <label htmlFor="firstName" className="block mb-1 text-zinc-300">First Name</label>
          <input
            {...register('firstName')}
            id="firstName"
            type="text"
            className="w-full px-3 py-2 rounded border border-zinc-700 bg-zinc-800 text-white focus:outline-none focus:border-red-700"
            autoComplete="given-name"
          />
          {errors.firstName && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.firstName.message}</span>}
        </div>
        <div style={{ marginBottom: '1rem' }}>
          <label htmlFor="lastName" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>Last Name</label>
          <input
            {...register('lastName')}
            id="lastName"
            type="text"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="family-name"
          />
          {errors.lastName && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.lastName.message}</span>}
        </div>
        <div style={{ marginBottom: '1rem' }}>
          <label htmlFor="email" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>Email</label>
          <input
            {...register('email')}
            id="email"
            type="email"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="email"
          />
          {errors.email && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.email.message}</span>}
        </div>
        <div style={{ marginBottom: '1rem' }}>
          <label htmlFor="password" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>Password</label>
          <input
            {...register('password')}
            id="password"
            type="password"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="new-password"
          />
          {errors.password && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.password.message}</span>}
        </div>
        <div style={{ marginBottom: '1.5rem' }}>
          <label htmlFor="confirmPassword" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>Confirm Password</label>
          <input
            {...register('confirmPassword', {
              validate: value => value === password || 'Passwords do not match'
            })}
            id="confirmPassword"
            type="password"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="new-password"
          />
          {errors.confirmPassword && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.confirmPassword.message}</span>}
        </div>
        <button disabled={isSubmitting || !isDirty} type="submit" className="w-full py-2.5 bg-[#e50914] text-white border-none rounded font-bold text-lg cursor-pointer disabled:bg-[#333] disabled:text-[#666] disabled:cursor-not-allowed">
          {isSubmitting ? "Registering..." : "Submit"}
        </button>
        {errors.root && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.root.message}</span>}
      </form>
    </div>
  );
};

export default Register;
