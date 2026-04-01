import { useForm } from "react-hook-form";
import { useMutation } from "@tanstack/react-query"
import { useAuthContext } from '../context/AuthContext'
import { useNavigate } from "react-router-dom";
import * as z from "zod";
import { zodResolver } from '@hookform/resolvers/zod';
import config from '../config';

const changePasswordSchema = z.object({
  password: z.string().regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    { error: "Password must be 8+ characters with uppercase, lowercase, number, and special character." }
  ),
  newPassword: z.string().regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    { error: "Password must be 8+ characters with uppercase, lowercase, number, and special character." }
  ),
  confirmPassword: z.string().regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    { error: "Password must be 8+ characters with uppercase, lowercase, number, and special character." }
  )
});

const ChangePassword = () => {

  const { user, token } = useAuthContext();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    watch,
    setError,
    formState: { errors, isSubmitting, isDirty }
  } = useForm({
    defaultValues: {
      password: '',
      newPassword: '',
      confirmPassword: '',
    },
    resolver: zodResolver(changePasswordSchema),
  });

  const onSubmit = (data) => {
    // Add registration logic here
    const { newPassword } = data;  // removes confirmPassord from the data to submit
    registerMutation.mutate(newPassword);
  };

  const registerMutation = useMutation({
    mutationFn: async (data) => {
      const response = await fetch(`${config.API_URL}/auth/${user._id}/changepassword`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },

        body: JSON.stringify(data)
      });

      //  Unsuccessful
      if (!response.ok) throw new Error(response)
      // Successful
      return await response.json()
    },
    // data here is response from mutationFn
    onSuccess: () => {
      // navigate somewhere else after successful change password
      navigate('/admin/users')
    },
    // errorResponse is from above
    onError: () => {
      setError("root", {
        message: "Error changing password. Please check your credentials and try again.",
      });
    }
  })

  const newPassword = watch('newPassword', '');

  return (
    <div className="max-w-md mx-auto my-8 p-8 bg-zinc-900 rounded-lg border border-zinc-800 shadow-lg">
      <h2 className="text-center mb-6 text-2xl font-bold text-white">Change Password</h2>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="mb-4">
          <label htmlFor="password" className="block mb-1 text-zinc-300">Original Password</label>
          <input
            {...register('password')}
            id="password"
            type="password"
            className="w-full px-3 py-2 rounded border border-zinc-700 bg-zinc-800 text-white focus:outline-none focus:border-red-700"
            autoComplete="new-password"
          />
          {errors.password && <span className="text-red-400 text-xs">{errors.password.message}</span>}
        </div>
        <div style={{ marginBottom: '1rem' }}>
          <label htmlFor="newPassword" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>New Password</label>
          <input
            {...register('newPassword')}
            id="newPassword"
            type="password"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="new-password"
          />
          {errors.newPassword && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.newPassword.message}</span>}
        </div>
        <div style={{ marginBottom: '1.5rem' }}>
          <label htmlFor="confirmPassword" style={{ display: 'block', marginBottom: 4, color: '#b3b3b3' }}>Confirm New Password</label>
          <input
            {...register('confirmPassword', {
              validate: value => value === newPassword || 'New Passwords do not match'
            })}
            id="confirmPassword"
            type="password"
            style={{ width: '100%', padding: 8, borderRadius: 4, border: '1px solid #444', background: '#333', color: '#fff' }}
            autoComplete="new-password"
          />
          {errors.confirmPassword && <span style={{ color: '#ff6b6b', fontSize: '10px' }}>{errors.confirmPassword.message}</span>}
        </div>
        <button disabled={isSubmitting || !isDirty} type="submit" className="w-full py-2.5 bg-[#e50914] text-white border-none rounded font-bold text-lg cursor-pointer disabled:bg-[#333] disabled:text-[#666] disabled:cursor-not-allowed">
          {isSubmitting ? "Changing Password..." : "Change Password"}
        </button>
      </form>
    </div>
  );
};

export default ChangePassword;
